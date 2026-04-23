import Foundation

extension AdminGamesViewModel {
    func deleteGame(id: String) async -> Bool {
        await performMutation(fallback: false) {
            let response = try await api.deleteGame(id: id)
            if response.deleteGame.success {
                DispatchQueue.main.async {
                    self.games.removeAll { $0.id == id }
                    self.totalCount -= 1
                    self.successMessage = "Game deleted successfully"
                }
                return true
            }

            setErrorMessage("Failed to delete game")
            return false
        }
    }

    func bulkDeleteGames(ids: [String]) async -> Int {
        await performMutation(fallback: 0) {
            let response = try await api.bulkDeleteGames(ids: ids)
            if response.bulkDeleteGames.success {
                DispatchQueue.main.async {
                    self.games.removeAll { ids.contains($0.id) }
                    self.totalCount -= response.bulkDeleteGames.deletedCount
                    self.successMessage = "Deleted \(response.bulkDeleteGames.deletedCount) game(s)"
                }
                return response.bulkDeleteGames.deletedCount
            }

            setErrorMessage("Failed to delete games")
            return 0
        }
    }
}
