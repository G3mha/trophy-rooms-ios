import SwiftUI

struct AdminGameFormSheet: View {
    @ObservedObject var viewModel: AdminGamesViewModel
    let game: AdminGameItem?
    var onSave: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var draft: AdminGameFormDraft
    @State private var isSaving = false
    @State private var showingRemovePlatformConfirmation = false
    @State private var igdbUrl = ""
    @State private var isImporting = false

    init(
        viewModel: AdminGamesViewModel,
        game: AdminGameItem?,
        onSave: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.game = game
        self.onSave = onSave
        _draft = StateObject(wrappedValue: AdminGameFormDraft(game: game))
    }

    private var controller: AdminGameFormController {
        AdminGameFormController(viewModel: viewModel, game: game)
    }

    var body: some View {
        NavigationStack {
            Form {
                if !controller.isEditing {
                    AdminGameIGDBImportSection(
                        igdbUrl: $igdbUrl,
                        isImporting: isImporting
                    ) {
                        importFromIGDB()
                    }
                }

                AdminGameIdentitySection(
                    title: $draft.title,
                    selectedType: $draft.selectedType
                )

                AdminGamePlatformsSection(
                    platforms: viewModel.platforms,
                    selectedPlatformIds: $draft.selectedPlatformIds,
                    isEditing: controller.isEditing
                )

                AdminGameBaseGamesSection(
                    selectedType: draft.selectedType,
                    selectedBaseGameIds: $draft.selectedBaseGameIds,
                    selectedBaseGames: $draft.selectedBaseGames,
                    excludedGameIds: draft.excludedGameIds
                )

                AdminGameOptionalMetadataSection(
                    description: $draft.description,
                    coverUrl: $draft.coverUrl
                )

                AdminGameCoverPreviewSection(coverUrl: draft.coverUrl)

                if game != nil {
                    AdminGamePlatformOverridesSection(
                        platformDescription: $draft.platformDescription,
                        platformCoverUrl: $draft.platformCoverUrl
                    )

                    AdminGameCoverPreviewSection(coverUrl: draft.platformCoverUrl)
                }

                if let error = viewModel.errorMessage {
                    AdminGameErrorSection(error: error)
                }

                if let game, game.gameFamilyId != nil {
                    AdminGameFamilyActionsSection(
                        game: game,
                        isSaving: isSaving
                    ) {
                        showingRemovePlatformConfirmation = true
                    }
                }
            }
            .navigationTitle(controller.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(controller.saveButtonTitle) {
                        save()
                    }
                    .disabled(!draft.isValid || isSaving || isImporting)
                }
            }
            .interactiveDismissDisabled(isSaving || isImporting)
            .alert("Remove Platform From Family", isPresented: $showingRemovePlatformConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    removePlatformFromFamily()
                }
            } message: {
                if let message = controller.removeConfirmationMessage {
                    Text(message)
                }
            }
        }
        .onChange(of: draft.selectedType) { _, newValue in
            draft.handleTypeChange(newValue)
        }
    }

    private func save() {
        isSaving = true

        Task {
            let success = await controller.save(draft: draft)

            DispatchQueue.main.async {
                isSaving = false
                if success {
                    onSave?()
                    dismiss()
                }
            }
        }
    }

    private func removePlatformFromFamily() {
        isSaving = true

        Task {
            let success = await controller.removePlatformFromFamily()

            DispatchQueue.main.async {
                isSaving = false
                if success {
                    onSave?()
                    dismiss()
                }
            }
        }
    }

    private func importFromIGDB() {
        let trimmedUrl = igdbUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUrl.isEmpty else { return }

        isImporting = true

        Task {
            let success = await controller.importFromIGDB(url: trimmedUrl)

            DispatchQueue.main.async {
                isImporting = false
                if success {
                    onSave?()
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    AdminGameFormSheet(viewModel: AdminGamesViewModel(), game: nil)
}
