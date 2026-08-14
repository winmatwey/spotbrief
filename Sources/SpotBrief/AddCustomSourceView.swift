import SwiftUI

/// Форма добавления собственного RSS-источника. Валидация только по формату
/// адреса — реальную работоспособность ленты после добавления показывает
/// тот же значок доступности, что и у встроенных источников.
struct AddCustomSourceView: View {
    @EnvironmentObject var customSources: CustomSourcesStore
    @EnvironmentObject var service: NewsAggregatorService
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var urlString = ""
    @State private var errorMessage: String?

    private var language: AppLanguage { settings.effectiveLanguage }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(L10n.t("addSource.namePlaceholder", language), text: $name)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text(L10n.t("addSource.nameLabel", language))
                }

                Section {
                    TextField(L10n.t("addSource.urlPlaceholder", language), text: $urlString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text(L10n.t("addSource.urlLabel", language))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle(L10n.t("addSource.title", language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("addSource.cancel", language)) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("addSource.add", language)) { submit() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                                  || urlString.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func submit() {
        let result = customSources.add(name: name, urlString: urlString)
        switch result {
        case .success:
            service.refreshSources()
            Task { await service.refreshAll() }
            dismiss()
        case .failure(let error):
            switch error {
            case .emptyName:
                errorMessage = L10n.t("addSource.errorEmptyName", language)
            case .invalidURL:
                errorMessage = L10n.t("addSource.errorInvalidURL", language)
            case .duplicateURL:
                errorMessage = L10n.t("addSource.errorDuplicate", language)
            }
        }
    }
}
