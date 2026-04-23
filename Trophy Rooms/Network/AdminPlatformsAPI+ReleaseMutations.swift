import Foundation

extension AdminPlatformsAPI {
    func createPlatformRelease(
        platformId: String,
        region: String,
        releaseDate: Date
    ) async throws -> CreatePlatformReleaseResponse {
        let mutation = """
        mutation CreatePlatformRelease($input: CreatePlatformReleaseInput!) {
            createPlatformRelease(input: $input) {
                success
                release {
                    id
                }
            }
        }
        """

        let formatter = ISO8601DateFormatter()
        let releaseDateString = formatter.string(from: releaseDate)

        let variables: [String: Any] = [
            "input": [
                "platformId": platformId,
                "region": region,
                "releaseDate": releaseDateString
            ]
        ]

        return try await networkService.fetch(query: mutation, variables: variables)
    }

    func updatePlatformRelease(
        id: String,
        region: String?,
        releaseDate: Date?
    ) async throws -> UpdatePlatformReleaseResponse {
        let mutation = """
        mutation UpdatePlatformRelease($id: ID!, $input: UpdatePlatformReleaseInput!) {
            updatePlatformRelease(id: $id, input: $input) {
                success
                release {
                    id
                }
            }
        }
        """

        var inputDict: [String: Any] = [:]
        if let region {
            inputDict["region"] = region
        }
        if let releaseDate {
            let formatter = ISO8601DateFormatter()
            inputDict["releaseDate"] = formatter.string(from: releaseDate)
        }

        return try await networkService.fetch(
            query: mutation,
            variables: [
                "id": id,
                "input": inputDict
            ]
        )
    }

    func deletePlatformRelease(id: String) async throws -> DeletePlatformReleaseResponse {
        let mutation = """
        mutation DeletePlatformRelease($id: ID!) {
            deletePlatformRelease(id: $id) {
                success
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["id": id])
    }
}
