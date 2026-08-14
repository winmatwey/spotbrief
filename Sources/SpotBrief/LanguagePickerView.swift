import SwiftUI

/// Экран выбора языка интерфейса: первый шаг онбординга и отдельный
/// экран, доступный из настроек для смены языка в любой момент.
struct LanguagePickerView: View {
    @EnvironmentObject var settings: SettingsStore

    /// Если открыт из настроек (а не при первом запуске), после выбора
    /// закрывается через это замыкание вместо продолжения онбординга.
    var onFinished: (() -> Void)?

    @State private var selected: AppLanguage?

    private var displayLanguage: AppLanguage {
        selected ?? settings.language ?? .russian
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "globe")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                    Text(L10n.t("language.title", displayLanguage))
                        .font(.title2.weight(.bold))
                    Text(L10n.t("language.subtitle", displayLanguage))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                VStack(spacing: 10) {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            selected = language
                        } label: {
                            HStack {
                                Text(language.flag)
                                    .font(.title2)
                                Text(language.nativeName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selected == language || (selected == nil && settings.language == language) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected(language) ? Color.orange.opacity(0.12) : Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isSelected(language) ? Color.orange : .clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                Spacer()

                Button {
                    confirm()
                } label: {
                    Text(L10n.t("common.continue", displayLanguage))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.large)
                .disabled(selected == nil && settings.language == nil)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(onFinished == nil)
    }

    private func isSelected(_ language: AppLanguage) -> Bool {
        selected == language || (selected == nil && settings.language == language)
    }

    private func confirm() {
        let language = selected ?? settings.language
        guard let language else { return }
        settings.language = language
        onFinished?()
    }
}
