import SwiftUI

@main
struct SpotBriefApp: App {
    @StateObject private var service = NewsAggregatorService()
    @StateObject private var settings = SettingsStore()
    @StateObject private var bookmarks = BookmarksStore()
    @StateObject private var readStore = ReadStore()
    @StateObject private var customSources = CustomSourcesStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(service)
                .environmentObject(settings)
                .environmentObject(bookmarks)
                .environmentObject(readStore)
                .environmentObject(customSources)
                .dynamicTypeSize(.large ... .accessibility2)
                .onAppear {
                    service.attach(settings: settings, customSources: customSources)
                }
        }
    }
}
