import Foundation

extension AdminAchievementSetsAPI {
    func createAchievementSet(
        title: String,
        type: AchievementSetType,
        visibility: AchievementSetVisibility,
        gameFamilyId: String,
        gameVersionId: String? = nil,
        dlcId: String? = nil
    ) async throws -> CreateAchievementSetResponse {
        let mutation = """
        mutation CreateAchievementSet($input: CreateAchievementSetInput!) {
            createAchievementSet(input: $input) {
                success
                achievementSet {
                    id
                    title
                    type
                    visibility
                    gameFamilyId
                    gameFamily {
                        id
                        title
                        slug
                    }
                    dlc {
                        id
                        name
                    }
                    achievementCount
                }
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "type": type.rawValue,
            "visibility": visibility.rawValue,
            "gameFamilyId": gameFamilyId
        ]

        if let gameVersionId, !gameVersionId.isEmpty {
            input["gameVersionId"] = gameVersionId
        }

        if let dlcId, !dlcId.isEmpty {
            input["dlcId"] = dlcId
        }

        return try await networkService.fetch(query: mutation, variables: ["input": input])
    }

    func updateAchievementSet(
        id: String,
        title: String,
        type: AchievementSetType,
        visibility: AchievementSetVisibility,
        gameFamilyId: String,
        gameVersionId: String? = nil,
        dlcId: String? = nil
    ) async throws -> UpdateAchievementSetResponse {
        let mutation = """
        mutation UpdateAchievementSet($id: ID!, $input: UpdateAchievementSetInput!) {
            updateAchievementSet(id: $id, input: $input) {
                success
                achievementSet {
                    id
                    title
                    type
                    visibility
                    gameFamilyId
                    gameFamily {
                        id
                        title
                        slug
                    }
                    dlc {
                        id
                        name
                    }
                    achievementCount
                }
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "type": type.rawValue,
            "visibility": visibility.rawValue,
            "gameFamilyId": gameFamilyId
        ]

        if let gameVersionId {
            input["gameVersionId"] = gameVersionId.isEmpty ? NSNull() : gameVersionId
        }

        if let dlcId {
            input["dlcId"] = dlcId.isEmpty ? NSNull() : dlcId
        }

        return try await networkService.fetch(
            query: mutation,
            variables: [
                "id": id,
                "input": input
            ]
        )
    }

    func deleteAchievementSet(id: String) async throws -> DeleteAchievementSetResponse {
        let mutation = """
        mutation DeleteAchievementSet($id: ID!) {
            deleteAchievementSet(id: $id) {
                success
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["id": id])
    }

    func bulkDeleteAchievementSets(ids: [String]) async throws -> BulkDeleteAchievementSetsResponse {
        let mutation = """
        mutation BulkDeleteAchievementSets($ids: [ID!]!) {
            bulkDeleteAchievementSets(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["ids": ids])
    }
}
