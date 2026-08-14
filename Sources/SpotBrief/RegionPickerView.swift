import SwiftUI

/// Экран выбора региона: второй шаг онбординга (после языка) и отдельный
/// экран, доступный из настроек для смены региона в любой момент.
struct RegionPickerView: View {
    @EnvironmentObject var service: NewsAggregatorService
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var checker = SourceAvailabilityChecker()

    /// Если экран открыт из настроек для смены региона (а не при первом запуске),
    /// после выбора он закрывается через это замыкание вместо onboarding-потока.
    var onFinished: (() -> Void)?

    @State private var selected: Region?
    @State private var isChecking = false

    private var language: AppLanguage { settings.effectiveLanguage }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                    Text(L10n.t("region.title", language))
                        .font(.title2.weight(.bold))
                    Text(L10n.t("region.subtitle", language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Region.allCases) { region in
                            Button {
                                selected = region
                            } label: {
                                HStack {
                                    Text(region.flag)
                                        .font(.title2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(region.localizedName(language))
                                            .font(.body.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text(L10n.tf("region.sourcesCount", language, NewsSource.sources(for: region).count))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selected == region {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.orange)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(selected == region ? Color.orange.opacity(0.12) : Color(.secondarySystemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(selected == region ? Color.orange : .clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                Button {
                    confirm()
                } label: {
                    if isChecking {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(L10n.t("common.continue", language))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.large)
                .disabled(selected == nil || isChecking)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(onFinished == nil)
    }

    private func confirm() {
        guard let selected else { return }
        isChecking = true
        service.updateRegion(selected)
        Task {
            await checker.check(NewsSource.sources(for: selected))
            isChecking = false
            onFinished?()
        }
    }
}
