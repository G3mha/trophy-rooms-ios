import SwiftUI

/// A router view that navigates directly to GameDetailView if there's only one game
/// for the given title, otherwise shows GameFamilyView with platform selection.
struct GameFamilyRouter: View {
    let title: String

    @State private var games: [GameSummary] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var hasNavigated = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading...")
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Button("Try Again") {
                        Task {
                            await fetchGames()
                        }
                    }
                }
            } else if games.count == 1, let game = games.first {
                // Single platform - go directly to game detail
                GameDetailView(gameId: game.id)
            } else {
                // Multiple platforms - show platform selection
                GameFamilyView(title: title)
            }
        }
        .task {
            await fetchGames()
        }
    }

    private func fetchGames() async {
        isLoading = true
        errorMessage = nil

        let query = """
        query GetGamesByTitle($title: String!) {
            gamesByTitle(title: $title) {
                id
                gameFamilyId
                title
                description
                coverUrl
                type
                baseGameFamilyIds
                platform { id name slug }
                achievementSetCount
                achievementCount
                trophyCount
            }
        }
        """

        let variables: [String: Any] = ["title": title]

        do {
            let response: GamesByTitleResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: variables
            )
            games = response.gamesByTitle
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        GameFamilyRouter(title: "Silent Hill: Shattered Memories")
    }
}
