import Foundation
import Combine

class UserProfileViewModel: ObservableObject {
    @Published var user: PublicUserWithAchievements?
    @Published var recentAchievements: [UserAchievementItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchUserProfile(userId: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetUserProfile($userId: ID!) {
            user(id: $userId) {
                id
                email
                name
                achievementCount
                trophyCount
                gamesWithAchievementsCount
                stats {
                    totalPoints
                    platinumCount
                    goldCount
                    silverCount
                    bronzeCount
                    completionRate
                    averagePointsPerGame
                }
                recentAchievements {
                    id
                    createdAt
                    achievement {
                        id
                        title
                        description
                        iconUrl
                        points
                        tier
                        achievementSet {
                            id
                            gameFamily {
                                id
                                title
                                coverUrl
                            }
                        }
                    }
                }
            }
        }
        """

        do {
            let response: UserProfileQueryResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["userId": userId]
            )
            DispatchQueue.main.async {
                self.user = response.user
                self.recentAchievements = response.user?.recentAchievements ?? []
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

// MARK: - Response Types

struct UserProfileQueryResponse: Decodable {
    let user: PublicUserWithAchievements?
}

struct PublicUserWithAchievements: Decodable, Identifiable {
    let id: String
    let email: String
    let name: String?
    let achievementCount: Int
    let trophyCount: Int
    let gamesWithAchievementsCount: Int
    let stats: UserProfileStats?
    let recentAchievements: [UserAchievementItem]
}

struct UserAchievementItem: Decodable, Identifiable {
    let id: String
    let createdAt: String
    let achievement: AchievementWithGame

    struct AchievementWithGame: Decodable {
        let id: String
        let title: String
        let description: String?
        let iconUrl: String?
        let points: Int
        let tier: AchievementTier?
        let achievementSet: AchievementSetWithGame

        struct AchievementSetWithGame: Decodable {
            let id: String
            let gameFamily: GameBasic

            struct GameBasic: Decodable {
                let id: String
                let title: String
                let coverUrl: String?
            }
        }
    }
}
