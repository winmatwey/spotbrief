import Foundation

/// Хранилище избранных новостей. Переживает перезапуск приложения (UserDefaults + JSON).
@MainActor
final class BookmarksStore: ObservableObject {
    @Published private(set) var bookmarks: [NewsItem] = []

    private let key = "spotbrief.bookmarks.v1"

    init() {
        load()
    }

    func isBookmarked(_ item: NewsItem) -> Bool {
        bookmarks.contains { $0.stableID == item.stableID }
    }

    func toggle(_ item: NewsItem) {
        if isBookmarked(item) {
            bookmarks.removeAll { $0.stableID == item.stableID }
        } else {
            bookmarks.insert(item, at: 0)
        }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        if let decoded = try? JSONDecoder().decode([NewsItem].self, from: data) {
            bookmarks = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

/// Отслеживает прочитанные новости, чтобы притемнять их в лентах.
@MainActor
final class ReadStore: ObservableObject {
    @Published private(set) var readIDs: Set<String> = []

    private let key = "spotbrief.read.v1"

    init() {
        if let saved = UserDefaults.standard.array(forKey: key) as? [String] {
            readIDs = Set(saved)
        }
    }

    func isRead(_ item: NewsItem) -> Bool {
        readIDs.contains(item.stableID)
    }

    func markRead(_ item: NewsItem) {
        guard !readIDs.contains(item.stableID) else { return }
        readIDs.insert(item.stableID)
        UserDefaults.standard.set(Array(readIDs), forKey: key)
    }
}

/// Офлайн-кэш последней успешно загруженной ленты — приложение показывает
/// эти новости мгновенно при запуске, ещё до завершения сетевого запроса.
enum NewsCache {
    private static let key = "spotbrief.cache.v1"
    private static let dateKey = "spotbrief.cache.date.v1"

    static func save(_ items: [NewsItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
            UserDefaults.standard.set(Date(), forKey: dateKey)
        }
    }

    static func load() -> (items: [NewsItem], date: Date)? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([NewsItem].self, from: data) else {
            return nil
        }
        let date = UserDefaults.standard.object(forKey: dateKey) as? Date
        return (items, date ?? Date())
    }
}
