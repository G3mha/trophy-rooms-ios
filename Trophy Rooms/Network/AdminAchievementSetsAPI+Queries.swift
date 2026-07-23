import Foundation

extension AdminAchievementSetsAPI {
    func fetchAchievementSets() async throws -> AdminAchievementSetsResponse {
        let query = """
        query GetAchievementSets {
            achievementSets {
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
                gameVersionId
                dlcId
                dlc {
                    id
                    name
                    slug
                    type
                }
                achievementCount
            }
        }
        """

        return try await networkService.fetch(query: query)
    }

    func fetchGames() async throws -> AdminGamesResponse {
        let query = """
        query GetGames {
            games(first: 500) {
                edges {
                    node {
                        id
                        gameFamilyId
                        title
                        description
                        coverUrl
                        type
                        platform {
                            id
                            name
                            slug
                        }
                        achievementSetCount
                    }
                }
            }
        }
        """

        return try await networkService.fetch(query: query)
    }

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

    func fetchDlcs(gameFamilyId: String) async throws -> DLCsResponse {
        let query = """
        query GetDLCs($gameFamilyId: ID!) {
            dlcs(gameFamilyId: $gameFamilyId) {
                id
                name
                slug
                type
                gameFamilyId
            }
        }
        """

        return try await networkService.fetch(
            query: query,
            variables: ["gameFamilyId": gameFamilyId]
        )
    }
}
