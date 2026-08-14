import Foundation
import SwiftUI

enum SortOrder: String, CaseIterable, Identifiable, Hashable {
    case newest
    case source
    case readingTime

    var id: String { rawValue }

    func localizedName(_ language: AppLanguage) -> String {
        switch self {
        case .newest: return L10n.t("sort.newest", language)
        case .source: return L10n.t("sort.source", language)
        case .readingTime: return L10n.t("sort.readingTime", language)
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("spotbrief.mutedSources") private var mutedSourcesRaw: String = ""
    @AppStorage("spotbrief.autoRefreshMinutes") var autoRefreshMinutes: Int = 0 // 0 = выключено
    @AppStorage("spotbrief.fontScale") var fontScale: Double = 1.0
    @AppStorage("spotbrief.sortOrderRaw") private var sortOrderRaw: String = SortOrder.newest.rawValue
    @AppStorage("spotbrief.regionRaw") private var regionRaw: String = ""
    @AppStorage("spotbrief.languageRaw") private var languageRaw: String = ""

    /// Регион, выбранный пользователем при первом запуске. `nil`, пока выбор
    /// не сделан — это и есть сигнал показать экран выбора региона.
    var region: Region? {
        get { Region(rawValue: regionRaw) }
        set { regionRaw = newValue?.rawValue ?? "" }
    }

    /// Язык интерфейса. `nil`, пока пользователь ни разу его не выбрал —
    /// сигнал показать экран выбора языка при первом запуске.
    var language: AppLanguage? {
        get { AppLanguage(rawValue: languageRaw) }
        set { languageRaw = newValue?.rawValue ?? "" }
    }

    var mutedSources: Set<String> {
        get { Set(mutedSourcesRaw.split(separator: "|").map(String.init)) }
        set { mutedSourcesRaw = newValue.joined(separator: "|") }
    }

    var sortOrder: SortOrder {
        get { SortOrder(rawValue: sortOrderRaw) ?? .newest }
        set { sortOrderRaw = newValue.rawValue }
    }

    func isMuted(_ source: NewsSource) -> Bool {
        mutedSources.contains(source.name)
    }

    func toggleMute(_ source: NewsSource) {
        var set = mutedSources
        if set.contains(source.name) {
            set.remove(source.name)
        } else {
            set.insert(source.name)
        }
        mutedSources = set
    }

    // MARK: - Локализация

    /// Текущий язык интерфейса с безопасным запасным значением до того,
    /// как пользователь сделает выбор на онбординге.
    var effectiveLanguage: AppLanguage { language ?? .russian }

    func t(_ key: String) -> String {
        L10n.t(key, effectiveLanguage)
    }

    /// Версия с подстановкой значений (%@ / %d) — отдельное имя от `t(_:)`,
    /// чтобы не полагаться на разрешение перегрузок Swift между обычным
    /// и variadic-параметром при нулевом числе аргументов.
    func tf(_ key: String, _ args: CVarArg...) -> String {
        String(format: L10n.t(key, effectiveLanguage), arguments: args)
    }
}
