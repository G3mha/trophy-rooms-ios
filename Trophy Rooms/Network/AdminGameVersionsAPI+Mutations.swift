import Foundation

extension AdminGameVersionsAPI {
    func createVersion(
        gameIds: [String],
        name: String,
        slug: String,
        description: String?,
        coverUrl: String?,
        dlcIds: [String]?,
        isDefault: Bool,
        digitalOnly: Bool
    ) async throws -> CreateGameVersionResponse {
        let mutation = """
        mutation CreateGameVersion($input: CreateGameVersionInput!) {
            createGameVersion(input: $input) {
                success
                gameVersion {
                    id
                    name
                    slug
                    description
                    coverUrl
                    effectiveCoverUrl
                    isDefault
                    games {
                        id
                        title
                    }
                    dlcs {
                        id
                        name
                        slug
                        type
                    }
                }
            }
        }
        """

        var input: [String: Any] = [
            "gameIds": gameIds,
            "name": name,
            "slug": slug
        ]

        if let description, !description.isEmpty {
            input["description"] = description
        }
        if let coverUrl, !coverUrl.isEmpty {
            input["coverUrl"] = coverUrl
        }
        if let dlcIds, !dlcIds.isEmpty {
            input["dlcIds"] = dlcIds
        }
        if isDefault {
            input["isDefault"] = isDefault
        }
        if digitalOnly {
            input["digitalOnly"] = digitalOnly
        }

        return try await networkService.fetch(query: mutation, variables: ["input": input])
    }

    func updateVersion(
        id: String,
        gameIds: [String],
        name: String,
        slug: String,
        description: String?,
        coverUrl: String?,
        dlcIds: [String]?,
        digitalOnly: Bool
    ) async throws -> UpdateGameVersionResponse {
        let mutation = """
        mutation UpdateGameVersion($id: ID!, $input: UpdateGameVersionInput!) {
            updateGameVersion(id: $id, input: $input) {
                success
                gameVersion {
                    id
                    name
                    slug
                    description
                    coverUrl
                    effectiveCoverUrl
                    isDefault
                    games {
                        id
                        title
                    }
                    dlcs {
                        id
                        name
                        slug
                        type
                    }
                }
            }
        }
        """

        var input: [String: Any] = [
            "gameIds": gameIds,
            "name": name,
            "slug": slug,
            "digitalOnly": digitalOnly
        ]

        if let description {
            input["description"] = description
        }
        if let coverUrl {
            input["coverUrl"] = coverUrl
        }
        if let dlcIds {
            input["dlcIds"] = dlcIds
        }

        return try await networkService.fetch(
            query: mutation,
            variables: [
                "id": id,
                "input": input
            ]
        )
    }

    func deleteVersion(id: String) async throws -> DeleteGameVersionResponse {
        let mutation = """
        mutation DeleteGameVersion($id: ID!) {
            deleteGameVersion(id: $id) {
                success
                deletedId
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["id": id])
    }

    func setDefaultVersion(id: String) async throws -> SetDefaultVersionResponse {
        let mutation = """
        mutation SetDefaultVersion($id: ID!) {
            setDefaultVersion(id: $id) {
                success
                gameVersion {
                    id
                    name
                    isDefault
                }
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["id": id])
    }

    func bulkDeleteVersions(ids: [String]) async throws -> BulkDeleteGameVersionsResponse {
        let mutation = """
        mutation BulkDeleteGameVersions($ids: [ID!]!) {
            bulkDeleteGameVersions(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["ids": ids])
    }
}
