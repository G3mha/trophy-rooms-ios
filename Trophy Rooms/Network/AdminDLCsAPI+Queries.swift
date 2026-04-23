import Foundation

extension AdminDLCsAPI {
    func fetchDLCs(gameFamilyId: String) async throws -> DLCsResponse {
        let query = """
        query GetDLCs($gameFamilyId: ID!) {
            dlcs(gameFamilyId: $gameFamilyId) {
                id
                name
                slug
                type
                description
                coverUrl
                effectiveCoverUrl
                releaseDate
                price
                gameFamilyId
                gameFamily {
                    id
                    title
                    slug
                }
                platforms {
                    id
                    name
                    slug
                }
                achievementSetCount
            }
        }
        """

        return try await networkService.fetch(
            query: query,
            variables: ["gameFamilyId": gameFamilyId]
        )
    }
}
