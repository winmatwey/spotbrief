import Foundation
import SwiftUI

/// Источник, добавленный пользователем вручную (не из курируемого списка региона).
/// Хранится отдельно от `NewsSource`, потому что нуждается в Codable-персистентности
/// и в собственной валидации при добавлении — сам `NewsSource` в остальном
/// приложении остаётся простым value-типом без этой логики.
struct CustomSource: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var feedURLString: String

    init(id: UUID = UUID(), name: String, feedURLString: String) {
        self.id = id
        self.name = name
        self.feedURLString = feedURLString
    }

    var feedURL: URL? { URL(string: feedURLString) }

    var asNewsSource: NewsSource? {
        guard let url = feedURL else { return nil }
        return NewsSource(name: name, feedURL: url)
    }
}

/// Хранилище пользовательских источников. Переживает перезапуск приложения
/// (UserDefaults + JSON), не зависит от выбранного региона — добавленный
/// источник доступен независимо от того, какой регион сейчас активен.
@MainActor
final class CustomSourcesStore: ObservableObject {
    @Published private(set) var sources: [CustomSource] = []

    private let key = "spotbrief.customSources.v1"

    enum AddError: Error {
        case emptyName
        case invalidURL
        case duplicateURL
    }

    init() {
        load()
    }

    /// Добавляет источник после базовой валидации. Не проверяет, что по адресу
    /// действительно лежит RSS/Atom — эту часть (реальная доступность и
    /// работоспособность ленты) берёт на себя тот же SourceAvailabilityChecker,
    /// что и для встроенных источников, сразу после добавления.
    @discardableResult
    func add(name: String, urlString: String) -> Result<CustomSource, AddError> {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else { return .failure(.emptyName) }

        // Многие пользователи копируют адрес без схемы ("example.com/rss") —
        // подставляем https:// по умолчанию, а не считаем это ошибкой.
        let normalized = trimmedURL.contains("://") ? trimmedURL : "https://\(trimmedURL)"
        guard let url = URL(string: normalized),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty else {
            return .failure(.invalidURL)
        }

        guard !sources.contains(where: { $0.feedURLString.caseInsensitiveCompare(normalized) == .orderedSame }) else {
            return .failure(.duplicateURL)
        }

        let source = CustomSource(name: trimmedName, feedURLString: normalized)
        sources.append(source)
        save()
        return .success(source)
    }

    func remove(_ source: CustomSource) {
        sources.removeAll { $0.id == source.id }
        save()
    }

    var asNewsSources: [NewsSource] {
        sources.compactMap(\.asNewsSource)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([CustomSource].self, from: data) else { return }
        sources = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(sources) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
