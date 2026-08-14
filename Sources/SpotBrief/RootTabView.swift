import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var settings: SettingsStore

    private var needsOnboarding: Bool {
        settings.language == nil || settings.region == nil
    }

    var body: some View {
        TabView {
            ContentView()
                .tabItem { Label(settings.t("tab.feed"), systemImage: "newspaper") }

            SearchView()
                .tabItem { Label(settings.t("tab.search"), systemImage: "magnifyingglass") }

            BookmarksView()
                .tabItem { Label(settings.t("tab.bookmarks"), systemImage: "bookmark.fill") }

            StatsView()
                .tabItem { Label(settings.t("tab.stats"), systemImage: "chart.pie.fill") }

            SettingsView()
                .tabItem { Label(settings.t("tab.settings"), systemImage: "gearshape.fill") }
        }
        // Первый запуск: пока не выбраны язык и регион, поверх всего приложения
        // показывается онбординг. Как только оба выбора сделаны, обложка сама закрывается.
        .fullScreenCover(isPresented: Binding(
            get: { needsOnboarding },
            set: { _ in }
        )) {
            OnboardingView()
        }
    }
}
