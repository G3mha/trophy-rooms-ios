import Foundation

extension AdminGamesAPI {
    func deleteGame(id: String) async throws -> DeleteGameResponse {
        let mutation = """
        mutation DeleteGame($id: ID!) {
            deleteGame(id: $id) {
                success
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["id": id])
    }

    func bulkDeleteGames(ids: [String]) async throws -> BulkDeleteGamesResponse {
        let mutation = """
        mutation BulkDeleteGames($ids: [ID!]!) {
            bulkDeleteGames(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        return try await networkService.fetch(query: mutation, variables: ["ids": ids])
    }
}
