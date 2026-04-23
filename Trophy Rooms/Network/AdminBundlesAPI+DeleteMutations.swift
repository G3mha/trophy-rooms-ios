import Foundation

extension AdminBundlesAPI {
    func deleteBundle(id: String) async throws -> DeleteBundleResponse {
        let mutation = """
        mutation DeleteBundle($id: ID!) {
            deleteBundle(id: $id) {
                success
                deletedId
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["id": id])
    }

    func bulkDeleteBundles(ids: [String]) async throws -> BulkDeleteBundlesResponse {
        let mutation = """
        mutation BulkDeleteBundles($ids: [ID!]!) {
            bulkDeleteBundles(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["ids": ids])
    }
}
