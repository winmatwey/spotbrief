import SwiftUI

/// Экран первого запуска целиком: сначала язык интерфейса, затем регион
/// (от него зависит набор источников). Переключается сам, как только
/// пользователь делает очередной выбор — SettingsStore публикует изменения.
struct OnboardingView: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        if settings.language == nil {
            LanguagePickerView()
        } else {
            RegionPickerView()
        }
    }
}
