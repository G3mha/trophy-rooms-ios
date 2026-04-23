import Foundation

extension AdminAchievementsAPI {
    func fetchAchievementSets() async throws -> AdminAchievementSetsResponse {
        let query = """
        query GetAchievementSets {
            achievementSets {
                id
                title
                type
                visibility
                game {
                    id
                    title
                }
                achievementCount
            }
        }
        """

        return try await networkService.fetch(query: query)
    }

    func fetchAchievements(setId: String) async throws -> AdminAchievementsResponse {
        let query = """
        query GetAchievementSet($id: ID!) {
            achievementSet(id: $id) {
                id
                title
                achievements {
                    id
                    title
                    description
                    iconUrl
                    points
                    tier
                    achievementSetId
                }
            }
        }
        """

        return try await networkService.fetch(query: query, variables: ["id": setId])
    }
}
