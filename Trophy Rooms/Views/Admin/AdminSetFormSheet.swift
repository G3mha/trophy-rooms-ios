import SwiftUI

struct AdminSetFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminAchievementSetsViewModel
    @StateObject private var draft: AdminSetFormDraft
    let achievementSet: AdminAchievementSet?
    @State private var isSaving = false

    init(viewModel: AdminAchievementSetsViewModel, achievementSet: AdminAchievementSet?) {
        self.viewModel = viewModel
        self.achievementSet = achievementSet
        _draft = StateObject(wrappedValue: AdminSetFormDraft(achievementSet: achievementSet))
    }

    private var controller: AdminSetFormController {
        AdminSetFormController(viewModel: viewModel, achievementSet: achievementSet)
    }

    var body: some View {
        NavigationStack {
            Form {
                AdminSetDetailsSection(
                    title: $draft.title,
                    selectedType: $draft.selectedType,
                    selectedVisibility: $draft.selectedVisibility
                )

                AdminSetGameSection(selectedGame: $draft.selectedGame)
                    .onChange(of: draft.selectedGame) { _, newValue in
                        draft.handleGameChange(newValue)
                        if let game = newValue, let gameFamilyId = game.gameFamilyId {
                            Task {
                                await viewModel.fetchVersions(gameFamilyId: gameFamilyId)
                                await viewModel.fetchDlcs(gameFamilyId: gameFamilyId)
                            }
                        } else {
                            viewModel.versions = []
                            viewModel.dlcs = []
                        }
                    }

                AdminSetVersionSection(
                    selectedGame: draft.selectedGame,
                    versions: viewModel.versions,
                    selectedVersionId: $draft.selectedVersionId
                )

                AdminSetDLCSection(
                    selectedGame: draft.selectedGame,
                    dlcs: viewModel.dlcs,
                    selectedDlcId: $draft.selectedDlcId
                )

                if let error = viewModel.errorMessage {
                    AdminSetErrorSection(error: error)
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
            if let gameFamilyId = draft.selectedGame?.gameFamilyId {
                await viewModel.fetchVersions(gameFamilyId: gameFamilyId)
                await viewModel.fetchDlcs(gameFamilyId: gameFamilyId)
            }
        }
    }

    private func save() async {
        guard let gameFamilyId = draft.selectedGame?.gameFamilyId else { return }

        isSaving = true
        let success = await controller.save(draft: draft, gameFamilyId: gameFamilyId)
        if success {
            dismiss()
        }
        isSaving = false
    }
}

#Preview {
    AdminSetFormSheet(viewModel: AdminAchievementSetsViewModel(), achievementSet: nil)
}
