import Foundation

extension AdminBundlesAPI {
    func createBundle(
        name: String,
        slug: String,
        type: BundleType,
        description: String?,
        coverUrl: String?,
        price: Double?,
        platformIds: [String]
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
                    platforms { id name slug }
                    platformCount
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
        if !platformIds.isEmpty {
            input["platformIds"] = platformIds
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
        platformIds: [String]
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
                    platforms { id name slug }
                    platformCount
                    gameFamilyCount
                    dlcCount
                }
            }
        }
        """

        var input: [String: Any] = [
            "name": name,
            "slug": slug,
            "type": type.rawValue,
            "platformIds": platformIds
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

        return try await networkService.fetch(
            query: mutation,
            variables: ["id": id, "input": input]
        )
    }
}
