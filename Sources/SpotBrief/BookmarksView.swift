import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject var bookmarks: BookmarksStore
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        NavigationStack {
            List {
                if bookmarks.bookmarks.isEmpty {
                    ContentUnavailableView(
                        settings.t("bookmarks.emptyTitle"),
                        systemImage: "bookmark",
                        description: Text(settings.t("bookmarks.emptyDescription"))
                    )
                } else {
                    ForEach(bookmarks.bookmarks) { item in
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
                    .onDelete { offsets in
                        // Сначала собираем сами новости по индексам, и только потом
                        // удаляем — если делать это в цикле по offsets напрямую,
                        // после первого toggle массив сдвигается и при мультивыборе
                        // удаляются не те закладки.
                        let itemsToRemove = offsets.map { bookmarks.bookmarks[$0] }
                        for item in itemsToRemove {
                            bookmarks.toggle(item)
                        }
                    }
                }
            }
            .navigationTitle(settings.t("tab.bookmarks"))
            .toolbar {
                if !bookmarks.bookmarks.isEmpty {
                    EditButton()
                }
            }
        }
    }
}
