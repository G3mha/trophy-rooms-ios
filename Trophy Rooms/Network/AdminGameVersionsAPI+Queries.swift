import Foundation

extension AdminGameVersionsAPI {
    func fetchVersions(gameFamilyId: String) async throws -> GameVersionsResponse {
        let query = """
        query GetGameVersions($gameFamilyId: ID!) {
            gameVersions(gameFamilyId: $gameFamilyId) {
                id
                name
                slug
                description
                coverUrl
                effectiveCoverUrl
                releaseDate
                isDefault
                digitalOnly
                games {
                    id
                    title
                    platform {
                        id
                        name
                        slug
                    }
                }
                dlcs {
                    id
                    name
                    slug
                    type
                }
                dlcCount
                achievementSetCount
            }
        }
        """

        return try await networkService.fetch(
            query: query,
            variables: ["gameFamilyId": gameFamilyId]
        )
    }

    func fetchFamilyGames(gameFamilyId: String) async throws -> GameFamilyGamesResponse {
        let query = """
        query GetGameFamilyGames($id: ID!) {
            gameFamily(id: $id) {
                games {
                    id
                    platform {
                        id
                        name
                        slug
                    }
                }
            }
        }
        """

        return try await networkService.fetch(
            query: query,
            variables: ["id": gameFamilyId]
        )
    }

    func fetchAvailableDlcs(gameFamilyId: String) async throws -> DLCsResponse {
        let query = """
        query GetDLCs($gameFamilyId: ID!) {
            dlcs(gameFamilyId: $gameFamilyId) {
                id
                name
                slug
                type
            }
        }
        """

        return try await networkService.fetch(
            query: query,
            variables: ["gameFamilyId": gameFamilyId]
        )
    }
}
