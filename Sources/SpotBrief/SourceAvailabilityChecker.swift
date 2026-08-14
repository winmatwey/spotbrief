import Foundation

enum SourceAvailability {
    case checking
    case available
    case unavailable
}

/// Проверяет, отвечает ли RSS-лента конкретного источника прямо сейчас
/// с устройства пользователя. Это и есть практическая проверка "доступности
/// в регионе": если источник заблокирован или недоступен там, где сейчас
/// находится пользователь, запрос с его устройства не пройдёт — так же,
/// как не открылся бы сайт в браузере.
@MainActor
final class SourceAvailabilityChecker: ObservableObject {
    // Ключ — адрес ленты (а не NewsSource.id): у NewsSource id генерируется
    // заново при каждой пересборке списка источников (см. refreshSources()),
    // например после добавления своего источника — при ключе по id это
    // сбрасывало статус ВСЕХ источников обратно на "проверяется", даже уже
    // проверенных, только потому что список источников пересобрали.
    // URL ленты — единственная по-настоящему стабильная часть NewsSource.
    @Published private(set) var statuses: [String: SourceAvailability] = [:]

    private let maxConcurrentChecks = 6

    /// Проверяет список источников параллельно (с ограничением на число
    /// одновременных запросов) и обновляет статус каждого по мере готовности,
    /// чтобы интерфейс мог показывать результаты постепенно, а не всё разом.
    func check(_ sources: [NewsSource]) async {
        for source in sources where statuses[key(for: source)] == nil {
            statuses[key(for: source)] = .checking
        }

        await withTaskGroup(of: (String, SourceAvailability).self) { group in
            var iterator = sources.makeIterator()
            var running = 0

            func addNext() {
                guard let source = iterator.next() else { return }
                running += 1
                // Ключ и URL считаем здесь, на MainActor, а не внутри
                // addTask — вызывать изолированный к актору key(for:) из
                // конкурентного замыкания без await нельзя.
                let sourceKey = key(for: source)
                let feedURL = source.feedURL
                group.addTask {
                    let result = await Self.probe(feedURL)
                    return (sourceKey, result)
                }
            }

            for _ in 0..<maxConcurrentChecks { addNext() }

            while let (key, result) = await group.next() {
                statuses[key] = result
                running -= 1
                addNext()
                if running == 0 { break }
            }
        }
    }

    func status(for source: NewsSource) -> SourceAvailability {
        statuses[key(for: source)] ?? .checking
    }

    func status(forURL url: URL) -> SourceAvailability {
        statuses[url.absoluteString] ?? .checking
    }

    private nonisolated func key(for source: NewsSource) -> String {
        source.feedURL.absoluteString
    }

    private static func probe(_ url: URL) async -> SourceAvailability {
        if await attempt(url, method: "HEAD") == .available {
            return .available
        }
        // Раньше откат на GET срабатывал только если HEAD выбрасывал сетевую
        // ошибку (throw). Но многие серверы просто ОТВЕЧАЮТ на HEAD кодом
        // 405 Method Not Allowed — это не throw, а обычный ответ, и такой
        // источник помечался "недоступен", даже когда лента прекрасно
        // открывается по GET. Теперь откатываемся на GET в любом случае,
        // когда HEAD не дал .available.
        return await attempt(url, method: "GET")
    }

    private static func attempt(_ url: URL, method: String) async -> SourceAvailability {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 8
        request.setValue("Mozilla/5.0 (compatible; SpotBriefApp/1.0)", forHTTPHeaderField: "User-Agent")
        guard let status = try? await performRequest(request) else { return .unavailable }
        return status
    }

    private static func performRequest(_ request: URLRequest) async throws -> SourceAvailability {
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { return .unavailable }
        // 2xx/3xx считаем доступным; некоторые ленты отвечают 403 на HEAD,
        // но это всё ещё значит "сервер достижим", так что не блокируем жёстко —
        // только явные ошибки соединения выше (timeout/DNS) дают unavailable.
        return (200..<400).contains(http.statusCode) ? .available : .unavailable
    }
}
