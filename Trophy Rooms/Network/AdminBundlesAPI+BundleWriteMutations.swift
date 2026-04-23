import Foundation

extension AdminBundlesAPI {
    func createBundle(
        name: String,
        slug: String,
        type: BundleType,
        description: String?,
        coverUrl: String?,
        price: Double?,
        platformId: String?
    ) async throws -> CreateBundleResponse {
        let mutation = """
        mutation CreateBundle($input: CreateBundleInput!) {
            createBundle(input: $input) {
                success
                bundle {
                    id
                    name
                    slug
                    type
                    description
                    coverUrl
                    price
                    platform { id name slug }
                    platformId
                    gameFamilyCount
                    dlcCount
                }
            }
        }
        """

        var input: [String: Any] = [
            "name": name,
            "slug": slug,
            "type": type.rawValue
        ]

        if let description, !description.isEmpty {
            input["description"] = description
        }
        if let coverUrl, !coverUrl.isEmpty {
            input["coverUrl"] = coverUrl
        }
        if let price {
            input["price"] = price
        }
        if let platformId, !platformId.isEmpty {
            input["platformId"] = platformId
        }

        return try await networkService.fetch(query: mutation, variables: ["input": input])
    }

    func updateBundle(
        id: String,
        name: String,
        slug: String,
        type: BundleType,
        description: String?,
        coverUrl: String?,
        price: Double?,
        platformId: String?
    ) async throws -> UpdateBundleResponse {
        let mutation = """
        mutation UpdateBundle($id: ID!, $input: UpdateBundleInput!) {
            updateBundle(id: $id, input: $input) {
                success
                bundle {
                    id
                    name
                    slug
                    type
                    description
                    coverUrl
                    price
                    platform { id name slug }
                    platformId
                    gameFamilyCount
                    dlcCount
                }
            }
        }
        """

        var input: [String: Any] = [
            "name": name,
            "slug": slug,
            "type": type.rawValue
        ]

        if let description {
            input["description"] = description
        }
        if let coverUrl {
            input["coverUrl"] = coverUrl
        }
        if let price {
            input["price"] = price
        }
        if let platformId {
            input["platformId"] = platformId
        }

        return try await networkService.fetch(
            query: mutation,
            variables: ["id": id, "input": input]
        )
    }
}
