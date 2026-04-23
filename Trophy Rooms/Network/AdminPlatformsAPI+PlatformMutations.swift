import Foundation

extension AdminPlatformsAPI {
    func createPlatform(
        name: String,
        slug: String,
        description: String?,
        consolePictureUrl: String?,
        promotionalPictures: [String]?
    ) async throws -> CreatePlatformResponse {
        let mutation = """
        mutation CreatePlatform($input: CreatePlatformInput!) {
            createPlatform(input: $input) {
                success
                platform {
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
        }
        """

        var inputDict: [String: Any] = [
            "name": name,
            "slug": slug
        ]
        if let description, !description.isEmpty {
            inputDict["description"] = description
        }
        if let consolePictureUrl, !consolePictureUrl.isEmpty {
            inputDict["consolePictureUrl"] = consolePictureUrl
        }
        if let promotionalPictures {
            inputDict["promotionalPictures"] = promotionalPictures
        }

        return try await networkService.fetch(query: mutation, variables: ["input": inputDict])
    }

    func updatePlatform(
        id: String,
        name: String,
        slug: String,
        description: String?,
        consolePictureUrl: String?,
        promotionalPictures: [String]?
    ) async throws -> UpdatePlatformResponse {
        let mutation = """
        mutation UpdatePlatform($id: ID!, $input: UpdatePlatformInput!) {
            updatePlatform(id: $id, input: $input) {
                success
                platform {
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
        }
        """

        var inputDict: [String: Any] = [
            "name": name,
            "slug": slug
        ]
        if let description {
            inputDict["description"] = description.isEmpty ? NSNull() : description
        }
        if let consolePictureUrl {
            inputDict["consolePictureUrl"] = consolePictureUrl.isEmpty ? NSNull() : consolePictureUrl
        }
        if let promotionalPictures {
            inputDict["promotionalPictures"] = promotionalPictures
        }

        return try await networkService.fetch(
            query: mutation,
            variables: [
                "id": id,
                "input": inputDict
            ]
        )
    }

    func deletePlatform(id: String) async throws -> DeletePlatformResponse {
        let mutation = """
        mutation DeletePlatform($id: ID!) {
            deletePlatform(id: $id) {
                success
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["id": id])
    }

    func bulkDeletePlatforms(ids: [String]) async throws -> BulkDeletePlatformsResponse {
        let mutation = """
        mutation BulkDeletePlatforms($ids: [ID!]!) {
            bulkDeletePlatforms(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["ids": ids])
    }
}
