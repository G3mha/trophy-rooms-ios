import Foundation
import Combine

class GameListViewModel: ObservableObject {
    @Published var games: [GameSummary] = []
    @Published var platforms: [Platform] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Pagination state
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    @Published var totalCount: Int = 0
    @Published var pageSize: Int = 25

    var hasNextPage: Bool { currentPage < totalPages }
    var hasPreviousPage: Bool { currentPage > 1 }

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

    func fetchGames(search: String?, platformId: String?, hasAchievements: Bool?, orderBy: String?, type: String? = nil, page: Int = 1) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetGamesPage($page: Int, $pageSize: Int, $filter: GamesFilterInput, $orderBy: GameOrderBy) {
            gamesPage(page: $page, pageSize: $pageSize, filter: $filter, orderBy: $orderBy) {
                items {
                    id
                    title
                    description
                    coverUrl
                    type
                    baseGameId
                    achievementSetCount
                    achievementCount
                    trophyCount
                    platform { id name slug }
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

        if let type = type {
            filter["type"] = type
        }

        if !filter.isEmpty {
            variables["filter"] = filter
        }

        if let orderBy = orderBy {
            variables["orderBy"] = orderBy
        }

        do {
            let response: GamesPageResponse = try await NetworkService.shared.fetch(query: query, variables: variables)
            DispatchQueue.main.async {
                self.games = response.gamesPage.items
                self.currentPage = response.gamesPage.page
                self.totalPages = response.gamesPage.totalPages
                self.totalCount = response.gamesPage.totalCount
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

    func goToNextPage(search: String?, platformId: String?, hasAchievements: Bool?, orderBy: String?, type: String? = nil) async {
        guard hasNextPage else { return }
        await fetchGames(search: search, platformId: platformId, hasAchievements: hasAchievements, orderBy: orderBy, type: type, page: currentPage + 1)
    }

    func goToPreviousPage(search: String?, platformId: String?, hasAchievements: Bool?, orderBy: String?, type: String? = nil) async {
        guard hasPreviousPage else { return }
        await fetchGames(search: search, platformId: platformId, hasAchievements: hasAchievements, orderBy: orderBy, type: type, page: currentPage - 1)
    }

    func goToPage(_ page: Int, search: String?, platformId: String?, hasAchievements: Bool?, orderBy: String?, type: String? = nil) async {
        let targetPage = max(1, min(page, totalPages))
        await fetchGames(search: search, platformId: platformId, hasAchievements: hasAchievements, orderBy: orderBy, type: type, page: targetPage)
    }
}
