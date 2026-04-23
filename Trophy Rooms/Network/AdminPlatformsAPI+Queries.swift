import Foundation

extension AdminPlatformsAPI {
    func fetchPlatforms() async throws -> AdminPlatformsResponse {
        let query = """
        query GetPlatforms {
            platforms {
                id
                name
                slug
                description
                consolePictureUrl
                promotionalPictures
                releases {
                    id
                    region
                    releaseDate
                }
            }
        }
        """

        return try await networkService.fetch(query: query)
    }
}
