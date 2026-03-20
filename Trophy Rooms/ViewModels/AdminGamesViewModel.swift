import Foundation
import Combine

class AdminGamesViewModel: ObservableObject {
    @Published var games: [AdminGame] = []
    @Published var platforms: [AdminPlatform] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var searchText: String = ""

    var filteredGames: [AdminGame] {
        if searchText.isEmpty {
            return games
        }
        return games.filter { game in
            game.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    func fetchGames() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetGames {
            games(first: 500) {
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
            }
        }
        """

        do {
            let response: AdminGamesResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.games = response.games.edges.map { $0.node }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
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
