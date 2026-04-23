import Foundation

extension AdminAchievementsAPI {
    func createAchievement(
        title: String,
        description: String?,
        iconUrl: String?,
        points: Int,
        tier: AchievementTier?,
        achievementSetId: String
    ) async throws -> CreateAchievementResponse {
        let mutation = """
        mutation CreateAchievement($input: CreateAchievementInput!) {
            createAchievement(input: $input) {
                success
                achievement {
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

        var input: [String: Any] = [
            "title": title,
            "points": points,
            "achievementSetId": achievementSetId
        ]
        if let description, !description.isEmpty {
            input["description"] = description
        }
        if let iconUrl, !iconUrl.isEmpty {
            input["iconUrl"] = iconUrl
        }
        if let tier {
            input["tier"] = tier.rawValue
        }

        return try await networkService.fetch(query: mutation, variables: ["input": input])
    }

    func updateAchievement(
        id: String,
        title: String,
        description: String?,
        iconUrl: String?,
        points: Int,
        tier: AchievementTier?
    ) async throws -> UpdateAchievementResponse {
        let mutation = """
        mutation UpdateAchievement($id: ID!, $input: UpdateAchievementInput!) {
            updateAchievement(id: $id, input: $input) {
                success
                achievement {
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

        var input: [String: Any] = [
            "title": title,
            "points": points
        ]
        if let description {
            input["description"] = description
        }
        if let iconUrl {
            input["iconUrl"] = iconUrl
        }
        if let tier {
            input["tier"] = tier.rawValue
        }

        return try await networkService.fetch(
            query: mutation,
            variables: [
                "id": id,
                "input": input
            ]
        )
    }

    func deleteAchievement(id: String) async throws -> DeleteAchievementResponse {
        let mutation = """
        mutation DeleteAchievement($id: ID!) {
            deleteAchievement(id: $id) {
                success
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["id": id])
    }

    func bulkDeleteAchievements(ids: [String]) async throws -> BulkDeleteAchievementsResponse {
        let mutation = """
        mutation BulkDeleteAchievements($ids: [ID!]!) {
            bulkDeleteAchievements(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["ids": ids])
    }

    func bulkCreateAchievements(
        achievementSetId: String,
        achievements: [[String: Any]]
    ) async throws -> BulkCreateAchievementsResponse {
        let mutation = """
        mutation BulkCreateAchievements($achievementSetId: ID!, $achievements: [BulkAchievementInput!]!) {
            bulkCreateAchievements(achievementSetId: $achievementSetId, achievements: $achievements) {
                success
                createdCount
                skippedCount
            }
        }
        """

        return try await networkService.fetch(
            query: mutation,
            variables: [
                "achievementSetId": achievementSetId,
                "achievements": achievements
            ]
        )
    }
}
