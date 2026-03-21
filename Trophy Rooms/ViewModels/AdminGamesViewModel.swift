import Foundation
import Combine

class AdminGamesViewModel: ObservableObject {
    @Published var games: [AdminGame] = []
    @Published var platforms: [AdminPlatform] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var searchText: String = ""
    @Published var currentPage: Int = 1

    private var pageCursors: [Int: String] = [:] // Store cursor for each page
    private var hasNextPage = false
    @Published var totalCount: Int = 0
    let pageSize = 50

    var filteredGames: [AdminGame] {
        if searchText.isEmpty {
            return games
        }
        return games.filter { game in
            game.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var totalPages: Int {
        max(1, Int(ceil(Double(totalCount) / Double(pageSize))))
    }

    var canGoNext: Bool {
        hasNextPage && !isLoading
    }

    var canGoPrevious: Bool {
        currentPage > 1 && !isLoading
    }

    func fetchGames(page: Int = 1) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetGames($first: Int!, $after: String) {
            games(first: $first, after: $after) {
                edges {
                    node {
                        id
                        title
                        description
                        coverUrl
                        platform {
                            id
                            name
                            slug
                        }
                        achievementSetCount
                    }
                }
                pageInfo {
                    hasNextPage
                    endCursor
                }
                totalCount
            }
        }
        """

        // Get cursor for the requested page (nil for first page)
        let cursor: String? = page > 1 ? pageCursors[page] : nil

        var variables: [String: Any] = ["first": pageSize]
        if let cursor = cursor {
            variables["after"] = cursor
        }

        do {
            let response: AdminGamesResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: variables
            )
            DispatchQueue.main.async {
                self.games = response.games.edges.map { $0.node }
                self.hasNextPage = response.games.pageInfo?.hasNextPage ?? false
                self.totalCount = response.games.totalCount ?? 0
                self.currentPage = page

                // Store cursor for the next page
                if let endCursor = response.games.pageInfo?.endCursor {
                    self.pageCursors[page + 1] = endCursor
                }

                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func goToNextPage() async {
        guard canGoNext else { return }
        await fetchGames(page: currentPage + 1)
    }

    func goToPreviousPage() async {
        guard canGoPrevious else { return }
        await fetchGames(page: currentPage - 1)
    }

    func goToFirstPage() async {
        guard currentPage != 1 else { return }
        pageCursors.removeAll()
        await fetchGames(page: 1)
    }

    func goToLastPage() async {
        // For last page, we need to fetch pages sequentially to get cursors
        // This is a limitation of cursor-based pagination
        guard totalPages > currentPage else { return }

        DispatchQueue.main.async {
            self.isLoading = true
        }

        // Fetch pages until we reach the last one
        var page = currentPage
        while page < totalPages {
            if pageCursors[page + 1] == nil && page > 1 {
                // Need to fetch this page first to get cursor
                await fetchPageSilently(page: page)
            }
            page += 1
        }

        await fetchGames(page: totalPages)
    }

    private func fetchPageSilently(page: Int) async {
        let query = """
        query GetGames($first: Int!, $after: String) {
            games(first: $first, after: $after) {
                edges {
                    node {
                        id
                    }
                }
                pageInfo {
                    hasNextPage
                    endCursor
                }
            }
        }
        """

        let cursor: String? = page > 1 ? pageCursors[page] : nil
        var variables: [String: Any] = ["first": pageSize]
        if let cursor = cursor {
            variables["after"] = cursor
        }

        do {
            let response: AdminGamesResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: variables
            )
            if let endCursor = response.games.pageInfo?.endCursor {
                DispatchQueue.main.async {
                    self.pageCursors[page + 1] = endCursor
                }
            }
        } catch {
            // Silently fail
        }
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

    func createGame(title: String, description: String?, coverUrl: String?, platformId: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation CreateGame($input: CreateGameInput!) {
            createGame(input: $input) {
                success
                game {
                    id
                    title
                    description
                    coverUrl
                    platform {
                        id
                        name
                        slug
                    }
                    achievementSetCount
                }
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "platformId": platformId
        ]
        if let description = description, !description.isEmpty {
            input["description"] = description
        }
        if let coverUrl = coverUrl, !coverUrl.isEmpty {
            input["coverUrl"] = coverUrl
        }

        let variables: [String: Any] = ["input": input]

        do {
            let response: CreateGameResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.createGame.success {
                await fetchGames()
                DispatchQueue.main.async {
                    self.successMessage = "Game created successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create game"
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

    func updateGame(id: String, title: String, description: String?, coverUrl: String?, platformId: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation UpdateGame($id: ID!, $input: UpdateGameInput!) {
            updateGame(id: $id, input: $input) {
                success
                game {
                    id
                    title
                    description
                    coverUrl
                    platform {
                        id
                        name
                        slug
                    }
                    achievementSetCount
                }
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "platformId": platformId
        ]
        if let description = description {
            input["description"] = description
        }
        if let coverUrl = coverUrl {
            input["coverUrl"] = coverUrl
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
                await fetchGames()
                DispatchQueue.main.async {
                    self.successMessage = "Game updated successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update game"
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
