import Foundation
import SwiftUI

@MainActor
final class NewsAggregatorService: ObservableObject {

    @Published private(set) var items: [NewsItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var errors: [String] = []
    @Published private(set) var sources: [NewsSource] = []

    private var autoRefreshTask: Task<Void, Never>?
    private weak var settings: SettingsStore?
    private weak var customSources: CustomSourcesStore?

    // Ограничение на число одновременных запросов полного текста статьи —
    // как и в SourceAvailabilityChecker, чтобы не заваливать источники
    // (и не упереться в системный лимит одновременных соединений) при
    // расширении сразу многих коротких сводок после обновления ленты.
    private let maxConcurrentExpansions = 6

    init() {
        if let cached = NewsCache.load() {
            self.items = cached.items
            self.lastUpdated = cached.date
        }
    }

    /// Подключает настройки и хранилище пользовательских источников, чтобы
    /// учитывать отключённые источники, автообновление, выбранный регион
    /// и вручную добавленные ленты. Если регион уже выбран (не первый
    /// запуск), сразу подставляет его источники.
    func attach(settings: SettingsStore, customSources: CustomSourcesStore) {
        self.settings = settings
        self.customSources = customSources
        refreshSources()
        scheduleAutoRefresh()
    }

    /// Меняет активный регион и его набор источников. Вызывается при первом
    /// выборе региона на онбординге и при смене региона в настройках.
    func updateRegion(_ region: Region) {
        settings?.region = region
        refreshSources()
        // Очищаем текущую ленту сразу, а не только после завершения refreshAll():
        // иначе пока грузятся источники нового региона, на экране ещё
        // какое-то время висят новости из старого региона.
        items = []
        lastUpdated = nil
        errors = []
        Task { await refreshAll() }
    }

    /// Пересобирает список активных источников: встроенные источники текущего
    /// региона плюс источники, добавленные пользователем вручную (они не
    /// привязаны к региону и доступны всегда). Вызывается при подключении
    /// настроек, при смене региона и после добавления/удаления
    /// пользовательского источника в настройках.
    func refreshSources() {
        let builtIn = settings?.region.map(NewsSource.sources(for:)) ?? []
        let custom = customSources?.asNewsSources ?? []
        sources = builtIn + custom
    }

    func scheduleAutoRefresh() {
        autoRefreshTask?.cancel()
        guard let minutes = settings?.autoRefreshMinutes, minutes > 0 else { return }
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(minutes) * 60_000_000_000)
                guard !Task.isCancelled else { return }
                await self?.refreshAll()
            }
        }
    }

    /// Параллельно опрашивает все источники, объединяет, классифицирует и суммирует новости.
    func refreshAll() async {
        // До выбора региона sources пуст — раньше это всё равно проставляло
        // lastUpdated = Date(), и в шапке ленты на миг мелькало "Обновлено: …",
        // хотя по факту ничего не грузилось.
        guard !sources.isEmpty else { return }

        isLoading = true
        errors = []
        defer { isLoading = false }

        let activeSources = sources.filter { settings?.isMuted($0) != true }
        var collected: [NewsItem] = []

        await withTaskGroup(of: Swift.Result<[NewsItem], NamedError>.self) { group in
            for source in activeSources {
                group.addTask {
                    let parser = RSSFeedParser(sourceName: source.name)
                    do {
                        let items = try await parser.parse(url: source.feedURL)
                        return .success(items)
                    } catch {
                        return .failure(NamedError(name: source.name, underlying: error))
                    }
                }
            }

            for await result in group {
                switch result {
                case .success(let parsedItems):
                    collected.append(contentsOf: parsedItems)
                case .failure(let err):
                    let language = settings?.effectiveLanguage ?? .russian
                    errors.append(L10n.tf("error.sourceFailed", language, err.name, err.underlying.localizedDescription))
                }
            }
        }

        // Отсеиваем типовой "мусорный" контент, который RSS-ленты подмешивают
        // к настоящим новостям (гороскопы, тесты/квизы, регулярная погода) —
        // см. NewsJunkFilter. Делаем это ДО классификации и суммаризации,
        // чтобы не тратить на такой контент вычисления впустую.
        collected = NewsJunkFilter.filter(collected)

        // Классификация по категориям
        var categorized = NewsCategorizer.categorizeAll(collected)

        // Суммаризация каждой новости
        for index in categorized.indices {
            categorized[index].summary = NewsSummarizer.summarize(categorized[index])
        }

        // Тизера из RSS <description> почти никогда не хватает на
        // NewsSummarizer.minSentences предложений — догружаем полный текст
        // статьи и пересчитываем сводку по нему для всех новостей, где сводки
        // не хватает, чтобы краткое содержание было развёрнутым везде, а не
        // только в открытой карточке новости.
        await expandShortSummaries(&categorized)

        // Сортировка по дате (свежие сверху), без даты — в конец
        categorized.sort { ($0.pubDate ?? .distantPast) > ($1.pubDate ?? .distantPast) }

        self.items = categorized
        self.lastUpdated = Date()
        NewsCache.save(categorized)
    }

    func search(_ query: String) -> [NewsItem] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let lowered = query.lowercased()
        return items.filter {
            $0.title.lowercased().contains(lowered) || $0.rawDescription.lowercased().contains(lowered)
        }
    }

    func items(in category: NewsCategory) -> [NewsItem] {
        items.filter { $0.category == category }
    }

    func count(in category: NewsCategory) -> Int {
        items.lazy.filter { $0.category == category }.count
    }

    /// Догружает полный текст статьи и пересчитывает по нему сводку для
    /// каждой новости, чья текущая сводка (построенная только по тизеру из
    /// RSS `<description>`) короче `NewsSummarizer.minSentences`. Новости без
    /// ссылки или те, где загрузка не удалась (источник недоступен, блокирует
    /// запрос и т.п.), остаются с тем, что уже есть, — придумывать
    /// недостающие предложения нельзя, это была бы уже не новость источника.
    private func expandShortSummaries(_ items: inout [NewsItem]) async {
        let candidateIndices = items.indices.filter { index in
            items[index].link != nil
            && NewsSummarizer.sentenceCount(in: items[index].summary) < NewsSummarizer.minSentences
            // Гороскопы, колонки читательских писем и подобные "сборные"
            // материалы — не один связный текст, а несколько разных
            // мини-тем подряд; экстрактивная суммаризация на них даёт
            // бессвязную кашу из фраз о разных темах. Отсеиваем такие ещё
            // до запроса — та же проверка, что и в NewsDetailView.
            && !ArticleContentFetcher.isLikelyMultiTopicContent(title: items[index].title, description: items[index].rawDescription)
        }
        guard !candidateIndices.isEmpty else { return }

        await withTaskGroup(of: (Int, String?).self) { group in
            var iterator = candidateIndices.makeIterator()
            var running = 0

            func addNext() {
                guard let index = iterator.next() else { return }
                // Как и в SourceAvailabilityChecker: URL и заголовок считаем здесь,
                // на MainActor, а не внутри addTask — обращаться к элементам
                // `items` из конкурентного замыкания без await нельзя.
                // Ссылка гарантированно есть — так уже отфильтровано в candidateIndices,
                // но проверяем ещё раз, чтобы не рассинхронизировать running/addTask.
                guard let link = items[index].link else { addNext(); return }
                running += 1
                let title = items[index].title
                group.addTask {
                    guard let fullText = try? await ArticleContentFetcher.fetchArticleText(from: link, relatedTo: title) else {
                        return (index, nil)
                    }
                    let expanded = NewsSummarizer.summarize(title: title, text: fullText, maxSentences: 8)
                    return (index, expanded)
                }
            }

            for _ in 0..<maxConcurrentExpansions { addNext() }

            while let (index, expanded) = await group.next() {
                running -= 1
                // Обновляем, только если реально получили более длинную сводку —
                // если полный текст статьи вдруг оказался короче тизера (бывает
                // на страницах-агрегаторах), тизер остаётся лучшим вариантом.
                if let expanded, NewsSummarizer.sentenceCount(in: expanded) > NewsSummarizer.sentenceCount(in: items[index].summary) {
                    items[index].summary = expanded
                }
                addNext()
                if running == 0 { break }
            }
        }
    }

    struct NamedError: Error {
        let name: String
        let underlying: Error
    }
}
