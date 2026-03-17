import Foundation
import Combine

class LibraryViewModel: ObservableObject {
    @Published var libraryItems: [LibraryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedStatus: GameStatus?

    var filteredItems: [LibraryItem] {
        if let status = selectedStatus {
            return libraryItems.filter { $0.status == status }
        }
        return libraryItems
    }

    var statusCounts: [GameStatus: Int] {
        var counts: [GameStatus: Int] = [:]
        for item in libraryItems {
            counts[item.status, default: 0] += 1
        }
        return counts
    }

    func fetchLibrary() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetMyLibrary {
            myGamesByStatus {
                id
                gameId
                gameTitle
                gameCoverUrl
                gameDescription
                achievementCount
                platformId
                platformName
                platformSlug
                status
                addedAt
                updatedAt
            }
        }
        """

        do {
            let response: LibraryResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.libraryItems = response.myGamesByStatus
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func setGameStatus(gameId: String, status: GameStatus, platformId: String? = nil) async -> Bool {
        let mutation = """
        mutation SetGameStatus($gameId: ID!, $status: GameStatus!, $platformId: ID) {
            setGameStatus(gameId: $gameId, status: $status, platformId: $platformId) {
                success
                status
                platformId
            }
        }
        """

        var variables: [String: Any] = ["gameId": gameId, "status": status.rawValue]
        if let platformId = platformId {
            variables["platformId"] = platformId
        }

        do {
            let response: SetGameStatusResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.setGameStatus.success {
                await fetchLibrary()
            }
            return response.setGameStatus.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func clearGameStatus(gameId: String) async -> Bool {
        let mutation = """
        mutation ClearGameStatus($gameId: ID!) {
            clearGameStatus(gameId: $gameId) {
                success
            }
        }
        """

        do {
            let response: ClearGameStatusResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["gameId": gameId]
            )
            if response.clearGameStatus.success {
                DispatchQueue.main.async {
                    self.libraryItems.removeAll { $0.gameId == gameId }
                }
            }
            return response.clearGameStatus.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
}
