import SwiftUI
import Charts

private struct CategoryCount: Identifiable {
    let category: NewsCategory
    let count: Int
    var id: String { category.rawValue }
}

private struct SourceCount: Identifiable {
    let source: String
    let count: Int
    var id: String { source }
}

struct StatsView: View {
    @EnvironmentObject var service: NewsAggregatorService
    @EnvironmentObject var readStore: ReadStore
    @EnvironmentObject var settings: SettingsStore

    private var categoryCounts: [CategoryCount] {
        NewsCategory.allCases
            .map { CategoryCount(category: $0, count: service.count(in: $0)) }
            .sorted { $0.count > $1.count }
    }

    private var sourceCounts: [SourceCount] {
        Dictionary(grouping: service.items, by: { $0.sourceName })
            .map { SourceCount(source: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private var readCount: Int {
        service.items.filter { readStore.isRead($0) }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section(settings.t("stats.overview")) {
                    LabeledContent(settings.t("stats.totalNews"), value: "\(service.items.count)")
                    LabeledContent(settings.t("stats.read"), value: "\(readCount)")
                    LabeledContent(settings.t("stats.sourcesCount"), value: "\(service.sources.count)")
                }

                Section(settings.t("stats.byCategory")) {
                    Chart(categoryCounts) { entry in
                        BarMark(
                            x: .value(settings.t("stats.chartCount"), entry.count),
                            y: .value(settings.t("stats.chartCategory"), entry.category.localizedName(settings.effectiveLanguage))
                        )
                        .foregroundStyle(by: .value(settings.t("stats.chartCategory"), entry.category.localizedName(settings.effectiveLanguage)))
                    }
                    .frame(height: 260)
                    .chartLegend(.hidden)
                }

                Section(settings.t("stats.bySource")) {
                    ForEach(sourceCounts) { entry in
                        HStack {
                            Text(entry.source)
                            Spacer()
                            Text("\(entry.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(settings.t("tab.stats"))
        }
    }
}
