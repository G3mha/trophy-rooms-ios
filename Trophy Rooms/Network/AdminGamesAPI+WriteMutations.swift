import Foundation

extension AdminGamesAPI {
    func importGameFamilyFromIGDBUrl(
        url: String
    ) async throws -> ImportGameFamilyFromIGDBUrlResponse {
        let mutation = """
        mutation ImportGameFamilyFromIGDBUrl($url: String!) {
            importGameFamilyFromIGDBUrl(url: $url) {
                success
                error {
                    code
                    message
                    field
                }
                gameFamilyId
            }
        }
        """

        return try await networkService.fetch(
            query: mutation,
            variables: ["url": url]
        )
    }

    func createGameFamily(
        title: String,
        description: String?,
        coverUrl: String?,
        platformIds: [String],
        type: GameType,
        baseGameFamilyIds: [String]?
    ) async throws -> CreateGameFamilyResponse {
        let mutation = """
        mutation CreateGameFamily($input: CreateGameFamilyInput!) {
            createGameFamily(input: $input) {
                success
                error {
                    code
                    message
                    field
                }
                gameFamilyId
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "platformIds": platformIds,
            "type": type.rawValue
        ]
        if let description, !description.isEmpty {
            input["description"] = description
        }
        if let coverUrl, !coverUrl.isEmpty {
            input["coverUrl"] = coverUrl
        }
        if let baseGameFamilyIds, !baseGameFamilyIds.isEmpty {
            input["baseGameFamilyIds"] = baseGameFamilyIds
        }

        return try await networkService.fetch(query: mutation, variables: ["input": input])
    }

    func createGame(
        title: String,
        description: String?,
        coverUrl: String?,
        platformId: String,
        type: GameType,
        baseGameFamilyIds: [String]?
    ) async throws -> CreateGameResponse {
        let mutation = """
        mutation CreateGame($input: CreateGameInput!) {
            createGame(input: $input) {
                success
                error {
                    code
                    message
                    field
                }
                game {
                    id
                }
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "platformId": platformId,
            "type": type.rawValue
        ]
        if let description, !description.isEmpty {
            input["description"] = description
        }
        if let coverUrl, !coverUrl.isEmpty {
            input["coverUrl"] = coverUrl
        }
        if let baseGameFamilyIds, !baseGameFamilyIds.isEmpty {
            input["baseGameFamilyIds"] = baseGameFamilyIds
        }

        return try await networkService.fetch(query: mutation, variables: ["input": input])
    }

    func addPlatformToGameFamily(
        gameFamilyId: String,
        platformId: String
    ) async throws -> AddPlatformToGameFamilyResponse {
        let mutation = """
        mutation AddPlatformToGameFamily($input: AddPlatformToGameFamilyInput!) {
            addPlatformToGameFamily(input: $input) {
                success
                error {
                    code
                    message
                    field
                }
                game {
                    id
                }
            }
        }
        """

        let input: [String: Any] = [
            "gameFamilyId": gameFamilyId,
            "platformId": platformId
        ]

        return try await networkService.fetch(query: mutation, variables: ["input": input])
    }

    func updateGame(
        id: String,
        title: String,
        description: String?,
        coverUrl: String?,
        platformId: String,
        type: GameType,
        baseGameFamilyIds: [String]?
    ) async throws -> UpdateGameResponse {
        let mutation = """
        mutation UpdateGame($id: ID!, $input: UpdateGameInput!) {
            updateGame(id: $id, input: $input) {
                success
                error {
                    code
                    message
                    field
                }
                game {
                    id
                }
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "platformId": platformId,
            "type": type.rawValue
        ]
        if let description {
            input["description"] = description
        }
        if let coverUrl {
            input["coverUrl"] = coverUrl
        }
        if let baseGameFamilyIds {
            input["baseGameFamilyIds"] = baseGameFamilyIds
        } else if type == .BASE_GAME {
            input["baseGameFamilyIds"] = [String]()
        }

        return try await networkService.fetch(
            query: mutation,
            variables: [
                "id": id,
                "input": input
            ]
        )
    }

    func cloneGameToPlatform(
        gameId: String,
        targetPlatformId: String,
        copyAchievementSets: Bool
    ) async throws -> CloneGameResponse {
        let mutation = """
        mutation CloneGameToPlatform($gameId: ID!, $targetPlatformId: ID!, $copyAchievementSets: Boolean) {
            cloneGameToPlatform(gameId: $gameId, targetPlatformId: $targetPlatformId, copyAchievementSets: $copyAchievementSets) {
                success
                game {
                    id
                }
                error {
                    code
                    message
                    field
                }
            }
        }
        """

        let variables: [String: Any] = [
            "gameId": gameId,
            "targetPlatformId": targetPlatformId,
            "copyAchievementSets": copyAchievementSets
        ]

        return try await networkService.fetch(query: mutation, variables: variables)
    }
}
