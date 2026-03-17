import Foundation
import Combine

class GameProgressViewModel: ObservableObject {
    @Published var allProgress: [GameProgress] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var completedGames: [GameProgress] {
        allProgress.filter { $0.hasTrophy }
    }

    var inProgressGames: [GameProgress] {
        allProgress.filter { !$0.hasTrophy && $0.earnedCount > 0 }
    }

    func fetchGameProgress() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetMyGameProgress {
            myGameProgress {
                gameId
                gameTitle
                gameCoverUrl
                earnedCount
                totalCount
                earnedPoints
                totalPoints
                percentComplete
                hasTrophy
                trophyEarnedAt
                lastActivityAt
                platformId
                platformName
                platformSlug
            }
        }
        """

        do {
            let response: GameProgressResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.allProgress = response.myGameProgress
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
