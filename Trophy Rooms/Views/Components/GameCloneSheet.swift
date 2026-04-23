import SwiftUI

/// Sheet for cloning a game to other platforms
struct GameCloneSheet: View {
    let gameId: String
    let gameTitle: String
    let currentPlatformId: String?

    @ObservedObject var viewModel: AdminGamesViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var draft = GameCloneDraft()

    private var controller: GameCloneController {
        GameCloneController(
            viewModel: viewModel,
            gameId: gameId,
            gameTitle: gameTitle,
            currentPlatformId: currentPlatformId
        )
    }

    var body: some View {
        NavigationStack {
            GameCloneFormContent(
                gameTitle: gameTitle,
                availablePlatforms: controller.availablePlatforms,
                selectedPlatformIds: $draft.selectedPlatformIds,
                copyAchievementSets: $draft.copyAchievementSets,
                errorMessage: viewModel.errorMessage
            )
            .navigationTitle("Clone Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Clone") {
                        cloneGame()
                    }
                    .disabled(!draft.isValid || draft.isCloning)
                }
            }
            .interactiveDismissDisabled(draft.isCloning)
            .overlay {
                if draft.isCloning {
                    GameCloneLoadingOverlay()
                }
            }
            .sheet(isPresented: $draft.showingResults) {
                CloneResultsSheet(results: draft.cloneResults) {
                    dismiss()
                }
            }
        }
    }

    private func cloneGame() {
        draft.isCloning = true
        draft.cloneResults = []

        Task {
            let results = await controller.clone(draft: draft)

            await MainActor.run {
                draft.cloneResults = results
                draft.isCloning = false

                let allSucceeded = results.allSatisfy { $0.success }
                if allSucceeded {
                    NotificationCenter.default.post(name: .adminGameDidUpdate, object: nil)
                    dismiss()
                } else {
                    draft.showingResults = true
                }
            }
        }
    }
}

#Preview {
    GameCloneSheet(
        gameId: "1",
        gameTitle: "Test Game",
        currentPlatformId: "1",
        viewModel: AdminGamesViewModel()
    )
}
