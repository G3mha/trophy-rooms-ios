import Foundation
import Combine

class AdminGamesViewModel: ObservableObject {
    @Published var games: [AdminGame] = []
    @Published var platforms: [AdminPlatform] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var searchText: String = ""

    private var endCursor: String?
    private var hasNextPage = false
    private var totalCount: Int = 0
    private let pageSize = 50

    var filteredGames: [AdminGame] {
        if searchText.isEmpty {
            return games
        }
        return games.filter { game in
            game.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var canLoadMore: Bool {
        hasNextPage && !isLoadingMore && searchText.isEmpty
    }

    func fetchGames() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.endCursor = nil
            self.hasNextPage = false
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

        let variables: [String: Any] = ["first": pageSize]

        do {
            let response: AdminGamesResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: variables
            )
            DispatchQueue.main.async {
                self.games = response.games.edges.map { $0.node }
                self.endCursor = response.games.pageInfo?.endCursor
                self.hasNextPage = response.games.pageInfo?.hasNextPage ?? false
                self.totalCount = response.games.totalCount ?? 0
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func loadMoreGames() async {
        guard canLoadMore, let cursor = endCursor else { return }

        DispatchQueue.main.async {
            self.isLoadingMore = true
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

        let variables: [String: Any] = ["first": pageSize, "after": cursor]

        do {
            let response: AdminGamesResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: variables
            )
            DispatchQueue.main.async {
                self.games.append(contentsOf: response.games.edges.map { $0.node })
                self.endCursor = response.games.pageInfo?.endCursor
                self.hasNextPage = response.games.pageInfo?.hasNextPage ?? false
                self.isLoadingMore = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoadingMore = false
            }
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
