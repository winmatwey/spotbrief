import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var service: NewsAggregatorService
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var customSources: CustomSourcesStore
    @StateObject private var checker = SourceAvailabilityChecker()
    @State private var showingRegionPicker = false
    @State private var showingLanguagePicker = false
    @State private var showingAddSource = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        showingLanguagePicker = true
                    } label: {
                        HStack {
                            Text(settings.effectiveLanguage.flag)
                            Text(settings.effectiveLanguage.nativeName)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text(settings.t("settings.language"))
                } footer: {
                    Text(settings.t("settings.languageFooter"))
                }

                Section {
                    Button {
                        showingRegionPicker = true
                    } label: {
                        HStack {
                            Text(settings.region?.flag ?? "🌍")
                            Text(settings.region?.localizedName(settings.effectiveLanguage) ?? settings.t("settings.regionNotSelected"))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } header: {
                    Text(settings.t("settings.region"))
                } footer: {
                    Text(settings.t("settings.regionFooter"))
                }

                Section(settings.t("settings.autoRefresh")) {
                    Picker(settings.t("settings.interval"), selection: $settings.autoRefreshMinutes) {
                        Text(settings.t("settings.off")).tag(0)
                        Text(settings.t("settings.minutes5")).tag(5)
                        Text(settings.t("settings.minutes15")).tag(15)
                        Text(settings.t("settings.minutes30")).tag(30)
                        Text(settings.t("settings.hour1")).tag(60)
                    }
                    .onChange(of: settings.autoRefreshMinutes) {
                        service.scheduleAutoRefresh()
                    }
                }

                Section(settings.t("settings.fontSize")) {
                    Slider(value: $settings.fontScale, in: 0.85...1.4, step: 0.05) {
                        Text(settings.t("settings.scale"))
                    }
                    Text(settings.t("settings.sampleTitle"))
                        .font(.body)
                        .scaleEffect(settings.fontScale, anchor: .leading)
                        .padding(.top, 4)
                }

                Section {
                    ForEach(builtInSources) { source in
                        Toggle(isOn: Binding(
                            get: { !settings.isMuted(source) },
                            set: { _ in settings.toggleMute(source) }
                        )) {
                            HStack(spacing: 8) {
                                availabilityIcon(for: checker.status(for: source))
                                Text(source.name)
                            }
                        }
                    }
                } header: {
                    Text(settings.tf("settings.sourcesHeader", builtInSources.count))
                } footer: {
                    Text(settings.t("settings.sourcesFooter"))
                }

                Section {
                    if customSources.sources.isEmpty {
                        Text(settings.t("settings.noCustomSources"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(customSources.sources) { source in
                            HStack(spacing: 8) {
                                if let url = source.feedURL {
                                    availabilityIcon(for: checker.status(forURL: url))
                                }
                                Text(source.name)
                            }
                        }
                        .onDelete { offsets in
                            let toRemove = offsets.map { customSources.sources[$0] }
                            for source in toRemove {
                                customSources.remove(source)
                            }
                            service.refreshSources()
                        }
                    }
                    Button {
                        showingAddSource = true
                    } label: {
                        Label(settings.t("settings.addSource"), systemImage: "plus.circle")
                    }
                } header: {
                    Text(settings.t("settings.customSources"))
                } footer: {
                    Text(settings.t("settings.customSourcesFooter"))
                }

                Section(settings.t("settings.about")) {
                    LabeledContent(settings.t("settings.appName"), value: settings.t("app.name"))
                    LabeledContent(settings.t("settings.newsSourcesCount"), value: "\(service.sources.count)")
                    Text(settings.t("settings.aboutFooter"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(settings.t("tab.settings"))
            .task(id: service.sources.map(\.id)) {
                await checker.check(service.sources)
            }
            .sheet(isPresented: $showingRegionPicker) {
                RegionPickerView(onFinished: { showingRegionPicker = false })
            }
            .sheet(isPresented: $showingLanguagePicker) {
                LanguagePickerView(onFinished: { showingLanguagePicker = false })
            }
            .sheet(isPresented: $showingAddSource) {
                AddCustomSourceView()
            }
        }
    }

    private var builtInSources: [NewsSource] {
        settings.region.map(NewsSource.sources(for:)) ?? []
    }

    @ViewBuilder
    private func availabilityIcon(for status: SourceAvailability) -> some View {
        switch status {
        case .checking:
            ProgressView()
                .controlSize(.mini)
        case .available:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        case .unavailable:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.caption)
        }
    }
}
