import SwiftUI

struct AdminGameFormSheetWrapper: View {
    let gameId: String
    @ObservedObject var viewModel: AdminGamesViewModel
    var onSave: (() -> Void)?

    @State private var gameToEdit: AdminGameItem?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading game...")
            } else if let game = gameToEdit {
                AdminGameFormSheet(
                    viewModel: viewModel,
                    game: game,
                    onSave: onSave
                )
            } else {
                Text("Game not found")
            }
        }
        .task {
            await loadGame()
        }
    }

    private func loadGame() async {
        await viewModel.fetchGame(id: gameId)
        await MainActor.run {
            gameToEdit = viewModel.gameToEdit
            isLoading = false
        }
    }
}
