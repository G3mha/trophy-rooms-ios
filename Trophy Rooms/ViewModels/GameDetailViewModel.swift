import Foundation

class GameDetailViewModel: ObservableObject {
    @Published var game: GameDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isInWishlist = false
    @Published var isWishlistLoading = false

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
                releaseDate
                developer
                publisher
                genre
                esrbRating
                screenshots
                platform { id name slug }
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
                        tier
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

    func checkWishlist(gameId: String) async {
        let query = """
        query IsGameInWishlist($gameId: ID!) {
            isGameInWishlist(gameId: $gameId)
        }
        """

        do {
            let response: WishlistCheckResponse = try await NetworkService.shared.fetch(query: query, variables: ["gameId": gameId])
            DispatchQueue.main.async {
                self.isInWishlist = response.isGameInWishlist
            }
        } catch {
            // Silently fail - user might not be logged in
        }
    }

    func toggleWishlist() async {
        guard let gameId = game?.id else { return }

        DispatchQueue.main.async {
            self.isWishlistLoading = true
        }

        let mutation = """
        mutation ToggleWishlist($gameId: ID!) {
            toggleWishlist(gameId: $gameId) {
                success
                isInWishlist
            }
        }
        """

        do {
            let response: WishlistMutationResponse = try await NetworkService.shared.fetch(query: mutation, variables: ["gameId": gameId])
            DispatchQueue.main.async {
                if let result = response.toggleWishlist {
                    self.isInWishlist = result.isInWishlist
                }
                self.isWishlistLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isWishlistLoading = false
            }
        }
    }
}
