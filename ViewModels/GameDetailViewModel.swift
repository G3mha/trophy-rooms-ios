import Foundation

class GameDetailViewModel: ObservableObject {
    @Published var game: GameDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchGame(id: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetGame($id: ID!) {
            game(id: $id) {
                id
                title
                description
                coverUrl
                trophyCount
                achievementSets {
                    id
                    title
                    type
                    visibility
                    createdByUserId
                    achievements {
                        id
                        title
                        description
                        iconUrl
                        points
                        isCompleted
                        userCount
                        achievementSetId
                    }
                }
            }
        }
        """

        do {
            let response: GameDetailResponse = try await NetworkService.shared.fetch(query: query, variables: ["id": id])
            DispatchQueue.main.async {
                self.game = response.game
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func toggleAchievement(_ achievement: Achievement) async {
        let achievementId = achievement.id

        let mutationName = achievement.isCompleted == true ? "UnmarkAchievementComplete" : "MarkAchievementComplete"
        let mutationField = achievement.isCompleted == true ? "unmarkAchievementComplete" : "markAchievementComplete"

        let mutation = """
        mutation \(mutationName)($achievementId: ID!) {
            \(mutationField)(achievementId: $achievementId) {
                success
            }
        }
        """

        do {
            let _: SimpleMutationResponse = try await NetworkService.shared.fetch(query: mutation, variables: ["achievementId": achievementId])
            if let gameId = game?.id {
                await fetchGame(id: gameId)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
