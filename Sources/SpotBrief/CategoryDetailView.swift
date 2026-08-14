import SwiftUI

struct CategoryDetailView: View {
    @EnvironmentObject var service: NewsAggregatorService
    @EnvironmentObject var bookmarks: BookmarksStore
    @EnvironmentObject var readStore: ReadStore
    @EnvironmentObject var settings: SettingsStore
    let category: NewsCategory

    private var sortedItems: [NewsItem] {
        let base = service.items(in: category)
        switch settings.sortOrder {
        case .newest:
            return base.sorted { ($0.pubDate ?? .distantPast) > ($1.pubDate ?? .distantPast) }
        case .source:
            return base.sorted { $0.sourceName < $1.sourceName }
        case .readingTime:
            return base.sorted { $0.readingTimeMinutes < $1.readingTimeMinutes }
        }
    }

    var body: some View {
        List {
            Section(settings.t("category.digest")) {
                Text(NewsSummarizer.digest(for: category, items: service.items, language: settings.effectiveLanguage))
                    .font(.callout)
                    .lineSpacing(4)
            }

            Section {
                Picker(settings.t("category.sortPicker"), selection: $settings.sortOrder) {
                    ForEach(SortOrder.allCases) { order in
                        Text(order.localizedName(settings.effectiveLanguage)).tag(order)
                    }
                }
                .pickerStyle(.menu)
            }

            Section(settings.tf("category.allNews", sortedItems.count)) {
                ForEach(sortedItems) { item in
                    NavigationLink {
                        NewsDetailView(item: item)
                    } label: {
                        NewsRow(item: item)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            bookmarks.toggle(item)
                        } label: {
                            Label(bookmarks.isBookmarked(item) ? settings.t("swipe.removeBookmark") : settings.t("swipe.addBookmark"),
                                  systemImage: bookmarks.isBookmarked(item) ? "bookmark.slash" : "bookmark")
                        }
                        .tint(.orange)
                    }
                }
            }
        }
        .navigationTitle(category.localizedName(settings.effectiveLanguage))
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct NewsRow: View {
    @EnvironmentObject var readStore: ReadStore
    @EnvironmentObject var settings: SettingsStore
    let item: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(readStore.isRead(item) ? .secondary : .primary)
                .lineLimit(3)
            Text(item.summary.isEmpty ? settings.t("summary.unavailable") : item.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic(item.summary.isEmpty)
                .lineLimit(2)
            HStack {
                Text(item.sourceName)
                if let date = item.pubDate {
                    Text("· \(date.formatted(date: .abbreviated, time: .shortened))")
                }
                Spacer()
                Label(settings.tf("newsRow.readingTimeShort", item.readingTimeMinutes), systemImage: "clock")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

struct NewsDetailView: View {
    @EnvironmentObject var bookmarks: BookmarksStore
    @EnvironmentObject var readStore: ReadStore
    @EnvironmentObject var settings: SettingsStore
    @ObservedObject private var speech = SpeechReader.shared
    let item: NewsItem

    /// Полный текст статьи, подгруженный по ссылке из RSS — как только он
    /// готов, краткое содержание пересчитывается из него и становится
    /// заметно длиннее и разнообразнее, чем при пересказе одного-двух
    /// предложений тизера из `<description>`.
    @State private var fullArticleText: String?
    @State private var isLoadingFullText = false

    private var isSpeakingThisItem: Bool {
        speech.isSpeaking && speech.speakingItemID == item.id
    }

    /// Показываемое краткое содержание: расширенное, если полный текст
    /// статьи уже подгружен, иначе — исходное, построенное из тизера RSS.
    private var displaySummary: String {
        guard let fullArticleText, !fullArticleText.isEmpty else { return item.summary }
        return NewsSummarizer.summarize(title: item.title, text: fullArticleText, maxSentences: 8)
    }

    private var isExpanded: Bool {
        fullArticleText != nil && displaySummary.count > item.summary.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(item.title)
                    .font(.title2.weight(.bold))

                HStack {
                    Label(item.sourceName, systemImage: "newspaper")
                    Spacer()
                    if let date = item.pubDate {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)

                Label(settings.tf("content.readingTime", item.readingTimeMinutes), systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(settings.t("detail.summary"))
                            .font(.headline)
                        Spacer()
                        Button {
                            speech.toggle(id: item.id, text: "\(item.title). \(displaySummary)",
                                          languageCode: settings.effectiveLanguage.speechLanguageCode)
                        } label: {
                            Label(isSpeakingThisItem ? settings.t("detail.stop") : settings.t("detail.listen"),
                                  systemImage: isSpeakingThisItem ? "stop.circle.fill" : "speaker.wave.2.fill")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                        .tint(isSpeakingThisItem ? .red : .orange)
                    }

                    Text(displaySummary.isEmpty ? settings.t("summary.unavailable") : displaySummary)
                        .font(.body)
                        .italic(displaySummary.isEmpty)
                        // Небольшая анимация при переходе от короткой версии к развёрнутой,
                        // чтобы подмена текста не выглядела резким "скачком".
                        .animation(.easeInOut(duration: 0.25), value: displaySummary)

                    if isLoadingFullText {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.mini)
                            Text(settings.t("detail.loadingFull"))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    } else if isExpanded {
                        Label(settings.t("detail.expandedFromArticle"), systemImage: "text.badge.checkmark")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                let tags = NewsSummarizer.keywords(for: item)
                if !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.orange.opacity(0.15))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                if !isExpanded && !item.rawDescription.isEmpty && item.rawDescription != item.summary {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(settings.t("detail.fullDescription"))
                            .font(.headline)
                        Text(item.rawDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    Button {
                        bookmarks.toggle(item)
                    } label: {
                        Label(bookmarks.isBookmarked(item) ? settings.t("detail.bookmarked") : settings.t("detail.bookmark"),
                              systemImage: bookmarks.isBookmarked(item) ? "bookmark.fill" : "bookmark")
                    }
                    .buttonStyle(.bordered)

                    if let link = item.link {
                        ShareLink(item: link) {
                            Label(settings.t("detail.share"), systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.top, 4)

                if let link = item.link {
                    Link(destination: link) {
                        Label(settings.t("detail.openSource"), systemImage: "safari")
                    }
                }
            }
            .padding()
        }
        .navigationTitle(item.category.localizedName(settings.effectiveLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            readStore.markRead(item)
        }
        .onDisappear {
            if isSpeakingThisItem {
                speech.stop()
            }
        }
        .task(id: item.id) {
            await loadFullArticle()
        }
    }

    /// Подгружает полный текст статьи по ссылке источника. Делается лениво —
    /// только когда пользователь реально открыл конкретную новость — а не для
    /// всей ленты сразу, иначе обновление списка стало бы мучительно долгим
    /// (десятки источников × десятки статей = сотни лишних запросов).
    private func loadFullArticle() async {
        guard fullArticleText == nil, let link = item.link else { return }

        // Гороскопы и колонки читательских писем (Dear Abby и т.п.) — плохой
        // кандидат для экстрактивной суммаризации: она рассчитана на один
        // связный текст, а тут по сути несколько разных мини-текстов подряд.
        // Разворачивать их в такую сводку не стоит — короткого тизера
        // из RSS для них и так достаточно. Основная часть таких материалов
        // уже отсеивается на уровне ленты (см. NewsJunkFilter), это —
        // подстраховка на случай, если что-то похожее всё же проскочит.
        guard !ArticleContentFetcher.isLikelyMultiTopicContent(title: item.title, description: item.rawDescription) else { return }

        isLoadingFullText = true
        defer { isLoadingFullText = false }
        fullArticleText = try? await ArticleContentFetcher.fetchArticleText(from: link, relatedTo: item.title)
    }
}
