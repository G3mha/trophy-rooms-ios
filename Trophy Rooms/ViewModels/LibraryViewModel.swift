import Foundation
import Combine

class LibraryViewModel: ObservableObject {
    @Published var libraryItems: [LibraryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedStatus: GameStatus?
    @Published var selectedPlatformId: String?

    var filteredItems: [LibraryItem] {
        var items = libraryItems

        if let status = selectedStatus {
            items = items.filter { $0.status == status }
        }

        if let platformId = selectedPlatformId {
            items = items.filter { $0.platformId == platformId }
        }

        return items
    }

    // Get unique platforms from library items
    var availablePlatforms: [(id: String, name: String, slug: String?)] {
        var seen = Set<String>()
        var platforms: [(id: String, name: String, slug: String?)] = []
        for item in libraryItems {
            if let platformId = item.platformId,
               let platformName = item.platformName,
               !seen.contains(platformId) {
                seen.insert(platformId)
                platforms.append((id: platformId, name: platformName, slug: item.platformSlug))
            }
        }
        return platforms.sorted { $0.name < $1.name }
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
                gameVersionId
                gameVersionName
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

    func setGameStatus(gameId: String, status: GameStatus, platformId: String? = nil, gameVersionId: String? = nil) async -> Bool {
        let mutation = """
        mutation SetGameStatus($gameId: ID!, $status: GameStatus!, $platformId: ID, $gameVersionId: ID) {
            setGameStatus(gameId: $gameId, status: $status, platformId: $platformId, gameVersionId: $gameVersionId) {
                success
                status
                platformId
                gameVersionId
            }
        }
        """

        var variables: [String: Any] = ["gameId": gameId, "status": status.rawValue]
        if let platformId = platformId {
            variables["platformId"] = platformId
        }
        if let gameVersionId = gameVersionId {
            variables["gameVersionId"] = gameVersionId
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
