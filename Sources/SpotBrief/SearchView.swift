import SwiftUI

struct SearchView: View {
    @EnvironmentObject var service: NewsAggregatorService
    @EnvironmentObject var settings: SettingsStore
    @State private var query = ""

    private var results: [NewsItem] {
        service.search(query)
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    ContentUnavailableView(
                        settings.t("search.emptyTitle"),
                        systemImage: "magnifyingglass",
                        description: Text(settings.t("search.emptyDescription"))
                    )
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    ForEach(results) { item in
                        NavigationLink {
                            NewsDetailView(item: item)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.category.localizedName(settings.effectiveLanguage) + " · " + item.sourceName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(settings.t("tab.search"))
            .searchable(text: $query, prompt: settings.t("search.prompt"))
        }
    }
}
