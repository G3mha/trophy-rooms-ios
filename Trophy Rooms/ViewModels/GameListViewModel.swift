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

    // Group games by title for consolidated display
    var gameGroups: [GameGroup] {
        groupGamesByTitle(games)
    }

    private func groupGamesByTitle(_ games: [GameSummary]) -> [GameGroup] {
        // Group by gameFamilyId if available, otherwise by normalized title
        var groups: [String: [GameSummary]] = [:]

        for game in games {
            let key = game.gameFamilyId ?? game.title.trimmingCharacters(in: .whitespaces).lowercased()
            if groups[key] == nil {
                groups[key] = []
            }
            groups[key]?.append(game)
        }

        return groups.map { (key, gameList) in
            let platforms = gameList.compactMap { $0.platform }
            let slug = gameList[0].title
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""

            return GameGroup(
                gameFamilyId: gameList[0].gameFamilyId,
                title: gameList[0].title,
                slug: slug,
                games: gameList,
                platforms: platforms,
                coverUrl: gameList.first(where: { $0.coverUrl != nil })?.coverUrl,
                totalAchievementCount: gameList.reduce(0) { $0 + $1.achievementCount },
                totalTrophyCount: gameList.reduce(0) { $0 + $1.trophyCount }
            )
        }.sorted { $0.title.lowercased() < $1.title.lowercased() }
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
                    gameFamilyId
                    title
                    description
                    coverUrl
                    type
                    baseGameFamilyId
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

    func setPageSize(_ newSize: Int, search: String?, platformId: String?, hasAchievements: Bool?, orderBy: String?, type: String? = nil) async {
        pageSize = newSize
        // Reset to page 1 when changing page size
        await fetchGames(search: search, platformId: platformId, hasAchievements: hasAchievements, orderBy: orderBy, type: type, page: 1)
    }
}

// MARK: - Page Size Options

enum PageSizeOption: Int, CaseIterable, Identifiable {
    case ten = 10
    case twentyFive = 25
    case fifty = 50
    case hundred = 100

    var id: Int { rawValue }

    var title: String {
        "\(rawValue) per page"
    }
}
