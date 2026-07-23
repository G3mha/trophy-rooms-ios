import Foundation

extension AdminGamesAPI {
    func fetchGames(page: Int, pageSize: Int, search: String?) async throws -> AdminGamesPageResponse {
        let query = """
        query AdminGames($page: Int!, $pageSize: Int!, $search: String) {
            adminGames(page: $page, pageSize: $pageSize, search: $search) {
                items {
                    id
                    gameFamilyId
                    title
                    description
                    coverUrl
                    platformCoverUrl
                    platformDescription
                    type
                    baseGameFamilyIds
                    platformId
                    platformName
                    platformSlug
                    achievementSetCount
                }
                totalCount
                page
                pageSize
                totalPages
            }
        }
        """

        var variables: [String: Any] = [
            "page": page,
            "pageSize": pageSize
        ]
        if let search, !search.isEmpty {
            variables["search"] = search
        }

        return try await networkService.fetch(query: query, variables: variables)
    }

    func fetchPlatforms() async throws -> AdminPlatformsResponse {
        let query = """
        query GetPlatforms {
            platforms {
                id
                name
                slug
            }
        }
        """

        return try await networkService.fetch(query: query)
    }

    func fetchGame(id: String) async throws -> GameForEditResponse {
        let query = """
        query GetGame($id: ID!) {
            game(id: $id) {
                id
                gameFamilyId
                title
                description
                coverUrl
                platformCoverUrl
                platformDescription
                type
                baseGameFamilies {
                    id
                    title
                    slug
                    coverUrl
                    type
                }
                platform {
                    id
                    name
                    slug
                }
            }
        }
        """

        return try await networkService.fetch(query: query, variables: ["id": id])
    }
}
