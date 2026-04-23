import SwiftUI

struct AdminGameVersionFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminGameVersionsViewModel
    @StateObject private var draft: AdminGameVersionFormDraft
    let gameFamilyId: String
    let version: GameVersion?
    @State private var isSaving = false

    init(viewModel: AdminGameVersionsViewModel, gameFamilyId: String, version: GameVersion?) {
        self.viewModel = viewModel
        self.gameFamilyId = gameFamilyId
        self.version = version
        _draft = StateObject(wrappedValue: AdminGameVersionFormDraft(version: version))
    }

    private var controller: AdminGameVersionFormController {
        AdminGameVersionFormController(
            viewModel: viewModel,
            api: viewModel.api,
            gameFamilyId: gameFamilyId,
            version: version
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                AdminGameVersionDetailsSection(
                    name: $draft.name,
                    slug: $draft.slug,
                    isEditing: controller.isEditing
                )

                AdminGameVersionPlatformsSection(
                    availableGames: draft.availableGames,
                    selectedGameIds: $draft.selectedGameIds,
                    isLoadingGames: draft.isLoadingGames
                )

                AdminGameVersionDescriptionSection(description: $draft.description)

                AdminGameVersionCoverSection(coverUrl: $draft.coverUrl)

                AdminGameVersionCoverPreviewSection(coverUrl: draft.coverUrl)

                AdminGameVersionDLCSection(
                    availableDlcs: draft.availableDlcs,
                    selectedDlcIds: $draft.selectedDlcIds,
                    isLoadingDlcs: draft.isLoadingDlcs
                )

                AdminGameVersionDefaultSection(
                    isEditing: controller.isEditing,
                    isDefault: $draft.isDefault
                )

                AdminGameVersionDistributionSection(digitalOnly: $draft.digitalOnly)

                if let error = viewModel.errorMessage {
                    AdminGameVersionErrorSection(error: error)
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
                        Task {
                            await save()
                        }
                    }
                    .disabled(!draft.isValid || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
        .task {
            await loadLookups()
        }
    }

    private func loadLookups() async {
        draft.isLoadingGames = true
        draft.isLoadingDlcs = true

        async let gamesTask = controller.fetchFamilyGames()
        async let dlcsTask = controller.fetchAvailableDlcs()

        let games = await gamesTask
        let dlcs = await dlcsTask

        draft.availableGames = games
        draft.isLoadingGames = false
        if !controller.isEditing && draft.selectedGameIds.isEmpty {
            draft.selectedGameIds = Set(games.map { $0.id })
        }

        draft.availableDlcs = dlcs
        draft.isLoadingDlcs = false
    }

    private func save() async {
        isSaving = true

        let success = await controller.save(draft: draft)
        if success {
            dismiss()
        }

        isSaving = false
    }
}

#Preview {
    AdminGameVersionFormSheet(
        viewModel: AdminGameVersionsViewModel(),
        gameFamilyId: "test-family-id",
        version: nil
    )
}
