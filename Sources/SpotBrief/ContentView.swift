import SwiftUI

struct ContentView: View {
    @EnvironmentObject var service: NewsAggregatorService
    @EnvironmentObject var bookmarks: BookmarksStore
    @EnvironmentObject var readStore: ReadStore
    @EnvironmentObject var settings: SettingsStore

    private var featuredItem: NewsItem? {
        service.items.first
    }

    var body: some View {
        NavigationStack {
            List {
                if let featured = featuredItem {
                    Section {
                        NavigationLink {
                            NewsDetailView(item: featured)
                        } label: {
                            FeaturedStoryCard(item: featured)
                        }
                        .buttonStyle(.plain)
                    } header: {
                        Text(settings.t("content.mainNow"))
                    }
                }

                if !service.errors.isEmpty {
                    Section {
                        ForEach(service.errors, id: \.self) { error in
                            Label(error, systemImage: "wifi.exclamationmark")
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }
                    } header: {
                        Text(settings.t("content.sourcesUnavailable"))
                    }
                }

                Section {
                    ForEach(NewsCategory.allCases) { category in
                        NavigationLink {
                            CategoryDetailView(category: category)
                        } label: {
                            CategoryRow(category: category, count: service.count(in: category))
                        }
                    }
                } header: {
                    if let updated = service.lastUpdated {
                        Text(settings.tf("content.updatedAt", updated.formatted(date: .omitted, time: .shortened)))
                    } else {
                        Text(settings.t("content.categories"))
                    }
                }
            }
            .navigationTitle(settings.t("app.name"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if service.isLoading {
                        ProgressView()
                    } else {
                        Button {
                            Task { await service.refreshAll() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .refreshable {
                await service.refreshAll()
            }
            .overlay {
                if service.isLoading && service.items.isEmpty {
                    ProgressView(settings.t("content.loading"))
                } else if !service.isLoading && service.items.isEmpty {
                    ContentUnavailableView(
                        settings.t("content.noData.title"),
                        systemImage: "newspaper",
                        description: Text(settings.tf("content.noData.description", service.sources.count))
                    )
                }
            }
            .task {
                if service.items.isEmpty {
                    await service.refreshAll()
                }
            }
        }
    }
}

private struct FeaturedStoryCard: View {
    @EnvironmentObject var settings: SettingsStore
    let item: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(item.category.localizedName(settings.effectiveLanguage), systemImage: item.category.symbolName)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(item.sourceName)
                    .font(.caption2)
            }
            .foregroundStyle(.white.opacity(0.85))

            Text(item.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(3)

            Text(item.summary.isEmpty ? settings.t("summary.unavailable") : item.summary)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .italic(item.summary.isEmpty)
                .lineLimit(2)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text(settings.tf("content.readingTime", item.readingTimeMinutes))
            }
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.75))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [.orange, .red.opacity(0.85)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct CategoryRow: View {
    @EnvironmentObject var settings: SettingsStore
    let category: NewsCategory
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: category.symbolName)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(color(for: category)))

            VStack(alignment: .leading) {
                Text(category.localizedName(settings.effectiveLanguage))
                    .font(.headline)
                Text(settings.tf("content.newsCount", count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func color(for category: NewsCategory) -> Color {
        switch category {
        case .politics: return .indigo
        case .sports: return .green
        case .economy: return .yellow
        case .technology: return .blue
        case .science: return .purple
        case .culture: return .pink
        case .incidents: return .red
        case .society: return .gray
        }
    }
}
