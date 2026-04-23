import Foundation

extension AdminDLCsAPI {
    func createDLC(
        gameFamilyId: String,
        name: String,
        slug: String,
        type: DLCType,
        description: String?,
        coverUrl: String?,
        price: Double?,
        platformIds: [String]
    ) async throws -> CreateDLCResponse {
        let mutation = """
        mutation CreateDLC($input: CreateDLCInput!) {
            createDLC(input: $input) {
                success
                dlc {
                    id
                    name
                    slug
                    type
                    description
                    coverUrl
                    effectiveCoverUrl
                    price
                    gameFamilyId
                    platforms {
                        id
                        name
                        slug
                    }
                }
            }
        }
        """

        var input: [String: Any] = [
            "gameFamilyId": gameFamilyId,
            "name": name,
            "slug": slug,
            "type": type.rawValue,
            "platformIds": platformIds
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

        return try await networkService.fetch(query: mutation, variables: ["input": input])
    }

    func updateDLC(
        id: String,
        name: String,
        slug: String,
        type: DLCType,
        description: String?,
        coverUrl: String?,
        price: Double?,
        platformIds: [String]
    ) async throws -> UpdateDLCResponse {
        let mutation = """
        mutation UpdateDLC($id: ID!, $input: UpdateDLCInput!) {
            updateDLC(id: $id, input: $input) {
                success
                dlc {
                    id
                    name
                    slug
                    type
                    description
                    coverUrl
                    effectiveCoverUrl
                    price
                    gameFamilyId
                    platforms {
                        id
                        name
                        slug
                    }
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

    func deleteDLC(id: String) async throws -> DeleteDLCResponse {
        let mutation = """
        mutation DeleteDLC($id: ID!) {
            deleteDLC(id: $id) {
                success
                deletedId
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["id": id])
    }

    func bulkDeleteDLCs(ids: [String]) async throws -> BulkDeleteDLCsResponse {
        let mutation = """
        mutation BulkDeleteDLCs($ids: [ID!]!) {
            bulkDeleteDLCs(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["ids": ids])
    }
}
