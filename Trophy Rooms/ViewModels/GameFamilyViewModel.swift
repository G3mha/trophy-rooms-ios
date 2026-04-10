import Foundation
import Combine

class GameFamilyViewModel: ObservableObject {
    @Published var games: [GameSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var totalAchievements: Int {
        games.reduce(0) { $0 + $1.achievementCount }
    }

    var totalTrophies: Int {
        games.reduce(0) { $0 + $1.trophyCount }
    }

    var coverUrl: String? {
        games.first(where: { $0.coverUrl != nil })?.coverUrl
    }

    var displayTitle: String {
        games.first?.title ?? ""
    }

    func fetchGamesByTitle(_ title: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

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
                achievementSetCount
                achievementCount
                trophyCount
                platform { id name slug }
            }
        }
        """

        let variables: [String: Any] = ["title": title]

        do {
            let response: GamesByTitleResponse = try await NetworkService.shared.fetch(query: query, variables: variables)
            DispatchQueue.main.async {
                self.games = response.gamesByTitle
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            print("Error fetching games by title: \(error)")
        }
    }
}
