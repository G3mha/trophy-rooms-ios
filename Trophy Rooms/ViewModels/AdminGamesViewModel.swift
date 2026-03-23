import Foundation
import Combine

class AdminGamesViewModel: ObservableObject {
    @Published var games: [AdminGameItem] = []
    @Published var platforms: [AdminPlatform] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var searchText: String = ""

    @Published var currentPage: Int = 1
    @Published var totalCount: Int = 0
    @Published var totalPages: Int = 1
    let pageSize = 50

    var filteredGames: [AdminGameItem] {
        // Search is now handled server-side
        return games
    }

    // Helper to find a game by ID for the base game picker
    func baseGameForId(_ id: String) -> AdminGameItem? {
        return games.first { $0.id == id }
    }

    var canGoNext: Bool {
        currentPage < totalPages && !isLoading
    }

    var canGoPrevious: Bool {
        currentPage > 1 && !isLoading
    }

    func fetchGames(page: Int = 1, search: String? = nil) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query AdminGames($page: Int!, $pageSize: Int!, $search: String) {
            adminGames(page: $page, pageSize: $pageSize, search: $search) {
                items {
                    id
                    title
                    description
                    coverUrl
                    type
                    baseGameId
                    platformId
                    platformName
                    platformSlug
                    achievementSetCount
                }
                totalCount
                page
                pageSize
                totalPages
            }
        }
        """

        var variables: [String: Any] = [
            "page": page,
            "pageSize": pageSize
        ]
        if let search = search, !search.isEmpty {
            variables["search"] = search
        }

        do {
            let response: AdminGamesPageResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: variables
            )
            DispatchQueue.main.async {
                self.games = response.adminGames.items
                self.currentPage = response.adminGames.page
                self.totalCount = response.adminGames.totalCount
                self.totalPages = response.adminGames.totalPages
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func goToPage(_ page: Int) async {
        guard page >= 1 && page <= totalPages && page != currentPage else { return }
        await fetchGames(page: page, search: searchText.isEmpty ? nil : searchText)
    }

    func goToNextPage() async {
        guard canGoNext else { return }
        await goToPage(currentPage + 1)
    }

    func goToPreviousPage() async {
        guard canGoPrevious else { return }
        await goToPage(currentPage - 1)
    }

    func goToFirstPage() async {
        await goToPage(1)
    }

    func goToLastPage() async {
        await goToPage(totalPages)
    }

    func search() async {
        await fetchGames(page: 1, search: searchText.isEmpty ? nil : searchText)
    }

    func fetchPlatforms() async {
        let query = """
        query GetPlatforms {
            platforms {
                id
                name
                slug
            }
        }
        """

        do {
            let response: AdminPlatformsResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.platforms = response.platforms
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func createGame(title: String, description: String?, coverUrl: String?, platformId: String, type: GameType = .BASE_GAME, baseGameId: String? = nil) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation CreateGame($input: CreateGameInput!) {
            createGame(input: $input) {
                success
                error {
                    code
                    message
                    field
                }
                game {
                    id
                }
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "platformId": platformId,
            "type": type.rawValue
        ]
        if let description = description, !description.isEmpty {
            input["description"] = description
        }
        if let coverUrl = coverUrl, !coverUrl.isEmpty {
            input["coverUrl"] = coverUrl
        }
        if let baseGameId = baseGameId {
            input["baseGameId"] = baseGameId
        }

        let variables: [String: Any] = ["input": input]

        do {
            let response: CreateGameResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.createGame.success {
                await fetchGames(page: 1)
                DispatchQueue.main.async {
                    self.successMessage = "Game created successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = response.createGame.error?.message ?? "Failed to create game"
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func updateGame(id: String, title: String, description: String?, coverUrl: String?, platformId: String, type: GameType = .BASE_GAME, baseGameId: String? = nil) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation UpdateGame($id: ID!, $input: UpdateGameInput!) {
            updateGame(id: $id, input: $input) {
                success
                error {
                    code
                    message
                    field
                }
                game {
                    id
                }
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "platformId": platformId,
            "type": type.rawValue
        ]
        if let description = description {
            input["description"] = description
        }
        if let coverUrl = coverUrl {
            input["coverUrl"] = coverUrl
        }
        // baseGameId can be explicitly set to null to clear it
        if let baseGameId = baseGameId {
            input["baseGameId"] = baseGameId
        } else if type == .BASE_GAME {
            // Clear baseGameId when switching to BASE_GAME
            input["baseGameId"] = NSNull()
        }

        let variables: [String: Any] = [
            "id": id,
            "input": input
        ]

        do {
            let response: UpdateGameResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.updateGame.success {
                await fetchGames(page: currentPage)
                DispatchQueue.main.async {
                    self.successMessage = "Game updated successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = response.updateGame.error?.message ?? "Failed to update game"
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func deleteGame(id: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation DeleteGame($id: ID!) {
            deleteGame(id: $id) {
                success
            }
        }
        """

        do {
            let response: DeleteGameResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            if response.deleteGame.success {
                DispatchQueue.main.async {
                    self.games.removeAll { $0.id == id }
                    self.totalCount -= 1
                    self.successMessage = "Game deleted successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete game"
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func bulkDeleteGames(ids: [String]) async -> Int {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation BulkDeleteGames($ids: [ID!]!) {
            bulkDeleteGames(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        do {
            let response: BulkDeleteGamesResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["ids": ids]
            )
            if response.bulkDeleteGames.success {
                DispatchQueue.main.async {
                    self.games.removeAll { ids.contains($0.id) }
                    self.totalCount -= response.bulkDeleteGames.deletedCount
                    self.successMessage = "Deleted \(response.bulkDeleteGames.deletedCount) game(s)"
                }
                return response.bulkDeleteGames.deletedCount
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete games"
                }
                return 0
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return 0
        }
    }
}
