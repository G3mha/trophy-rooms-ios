import Foundation
import Combine

class GameListViewModel: ObservableObject {
    @Published var games: [GameSummary] = []
    @Published var platforms: [Platform] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

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
            let response: PlatformsResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.platforms = response.platforms
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func fetchGames(search: String?, platformId: String?, hasAchievements: Bool?, orderBy: String?) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetGames($first: Int, $filter: GamesFilterInput, $orderBy: GameOrderBy) {
            games(first: $first, filter: $filter, orderBy: $orderBy) {
                edges {
                    node {
                        id
                        title
                        description
                        coverUrl
                        achievementSetCount
                        achievementCount
                        trophyCount
                        platform { id name slug }
                    }
                }
            }
        }
        """

        var variables: [String: Any] = ["first": 50]
        var filter: [String: Any] = [:]

        if let search = search, !search.isEmpty {
            filter["search"] = search
        }

        if let platformId = platformId, !platformId.isEmpty {
            filter["platformId"] = platformId
        }

        if let hasAchievements = hasAchievements {
            filter["hasAchievements"] = hasAchievements
        }

        if !filter.isEmpty {
            variables["filter"] = filter
        }

        if let orderBy = orderBy {
            variables["orderBy"] = orderBy
        }

        do {
            let response: GameListResponse = try await NetworkService.shared.fetch(query: query, variables: variables)
            DispatchQueue.main.async {
                self.games = response.games.edges.map { $0.node }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            print("Error fetching games: \(error)")
        }
    }
}
