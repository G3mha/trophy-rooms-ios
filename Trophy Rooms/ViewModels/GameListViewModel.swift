import Foundation
import Combine

class GameListViewModel: ObservableObject {
    @Published var games: [GameSummary] = []
    @Published var platforms: [Platform] = []
    @Published var isLoading = false
    /// Appending the next page - kept separate from `isLoading` so the grid
    /// stays on screen instead of being replaced by a full-page spinner
    @Published var isLoadingMore = false
    /// Synchronous re-entrancy latch for loadNextPage - see the note there
    private var isFetchingMore = false
    @Published var errorMessage: String?

    // Pagination state
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    /// Games (families) matching the filters. Not gamesPage.totalCount,
    /// which counts one row per platform edition.
    @Published var totalCount: Int = 0
    /// Fetch batch size for infinite scroll - an implementation detail,
    /// not a user-facing setting
    private let pageSize = 25

    var hasNextPage: Bool { currentPage < totalPages }

    // Group games by title for consolidated display
    var gameGroups: [GameGroup] {
        groupGamesByTitle(games)
    }

    /// Groups platform rows into one entry per game family, preserving the
    /// order the server returned them in.
    ///
    /// Do NOT re-sort here. The server already ordered the page per the user's
    /// Sort By choice, and with infinite scroll a client-side sort inserts each
    /// new page throughout the existing list instead of appending to the end -
    /// which reshuffles content above the viewport and makes the scroll jump.
    private func groupGamesByTitle(_ games: [GameSummary]) -> [GameGroup] {
        var groups: [String: [GameSummary]] = [:]
        var keyOrder: [String] = []

        for game in games {
            let key = game.gameFamilyId ?? game.title.trimmingCharacters(in: .whitespaces).lowercased()
            if groups[key] == nil {
                groups[key] = []
                keyOrder.append(key)
            }
            groups[key]?.append(game)
        }

        return keyOrder.compactMap { key -> GameGroup? in
            guard let gameList = groups[key], let first = gameList.first else { return nil }
            let platforms = gameList.compactMap { $0.platform }
            let slug = first.title
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""

            return GameGroup(
                gameFamilyId: first.gameFamilyId,
                title: first.title,
                slug: slug,
                games: gameList,
                platforms: platforms,
                coverUrl: gameList.first(where: { $0.coverUrl != nil })?.coverUrl,
                totalAchievementCount: gameList.reduce(0) { $0 + $1.achievementCount },
                totalTrophyCount: gameList.reduce(0) { $0 + $1.trophyCount }
            )
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

    func fetchGames(search: String?, platformId: String?, hasAchievements: Bool?, orderBy: String?, type: String? = nil, page: Int = 1, append: Bool = false) async {
        DispatchQueue.main.async {
            if append {
                self.isLoadingMore = true
            } else {
                self.isLoading = true
            }
            self.errorMessage = nil
        }

        let query = """
        query GetGamesPage($page: Int, $pageSize: Int, $filter: GamesFilterInput, $familyFilter: GameFamiliesFilterInput, $orderBy: GameOrderBy, $withFamilyCount: Boolean!) {
            gamesPage(page: $page, pageSize: $pageSize, filter: $filter, orderBy: $orderBy) {
                items {
                    id
                    gameFamilyId
                    title
                    description
                    coverUrl
                    type
                    baseGameFamilyIds
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
            gameFamiliesPage(pageSize: 1, filter: $familyFilter) @include(if: $withFamilyCount) {
                totalCount
            }
        }
        """

        // The family count can't change between pages of the same filters,
        // so only the first page pays for it
        var variables: [String: Any] = [
            "page": page,
            "pageSize": pageSize,
            "withFamilyCount": !append
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
            // GameFamiliesFilterInput takes the same fields
            variables["filter"] = filter
            variables["familyFilter"] = filter
        }

        if let orderBy = orderBy {
            variables["orderBy"] = orderBy
        }

        do {
            let response: GamesPageResponse = try await NetworkService.shared.fetch(query: query, variables: variables)
            DispatchQueue.main.async {
                if append {
                    // Guard against duplicates: ordering ties across page
                    // boundaries can return the same row twice
                    let existing = Set(self.games.map(\.id))
                    self.games += response.gamesPage.items.filter { !existing.contains($0.id) }
                } else {
                    self.games = response.gamesPage.items
                }
                self.currentPage = response.gamesPage.page
                self.totalPages = response.gamesPage.totalPages
                if let familyCount = response.gameFamiliesPage?.totalCount {
                    self.totalCount = familyCount
                }
                self.isLoading = false
                self.isLoadingMore = false
            }
        } catch {
            // Swiping between the paged tabs tears down the lazy view, which
            // cancels any in-flight append. That is normal lifecycle, not a
            // failure - surfacing it would replace the grid with an error.
            if error is CancellationError || (error as? URLError)?.code == .cancelled {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isLoadingMore = false
                }
                return
            }

            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.isLoadingMore = false
            }
            print("Error fetching games: \(error)")
        }
    }

    /// Appends the next page for infinite scroll. Safe to call repeatedly -
    /// it no-ops while a load is in flight or when the catalog is exhausted.
    func loadNextPage(search: String?, platformId: String?, hasAchievements: Bool?, orderBy: String?, type: String? = nil) async {
        // The published flags are set inside DispatchQueue.main.async, so they
        // can't gate re-entrancy: two callers would both pass the guard before
        // either assignment lands. This flag flips synchronously.
        guard hasNextPage, !isLoading, !isFetchingMore else { return }
        isFetchingMore = true
        defer { isFetchingMore = false }

        await fetchGames(
            search: search,
            platformId: platformId,
            hasAchievements: hasAchievements,
            orderBy: orderBy,
            type: type,
            page: currentPage + 1,
            append: true
        )
    }

    func goToNextPage(search: String?, platformId: String?, hasAchievements: Bool?, orderBy: String?, type: String? = nil) async {
        guard hasNextPage else { return }
        await fetchGames(search: search, platformId: platformId, hasAchievements: hasAchievements, orderBy: orderBy, type: type, page: currentPage + 1)
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
