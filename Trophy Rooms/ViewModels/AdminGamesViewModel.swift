import Foundation
import Combine

// MARK: - Admin Game Group (for grouped display)

struct AdminGameGroup: Identifiable {
    let gameFamilyId: String?
    let title: String
    let coverUrl: String?
    let games: [AdminGameItem]

    var id: String { gameFamilyId ?? games.first?.id ?? UUID().uuidString }

    var isSingleGame: Bool { games.count == 1 }

    var platforms: [String] {
        games.compactMap { $0.platformName }
    }

    var totalAchievementSets: Int {
        games.reduce(0) { $0 + $1.achievementSetCount }
    }
}

class AdminGamesViewModel: ObservableObject {
    @Published var games: [AdminGameItem] = []
    @Published var platforms: [AdminPlatform] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var searchText: String = ""
    @Published var isGrouped: Bool = true

    @Published var currentPage: Int = 1
    @Published var totalCount: Int = 0
    @Published var totalPages: Int = 1
    @Published var pageSize: Int = 50

    /// Single game for editing (used by inline admin toolbar)
    @Published var gameToEdit: AdminGameItem?

    var filteredGames: [AdminGameItem] {
        // Search is now handled server-side
        return games
    }

    var groupedGames: [AdminGameGroup] {
        // Group games by gameFamilyId
        var groups: [String: [AdminGameItem]] = [:]
        var noFamilyGames: [AdminGameItem] = []

        for game in games {
            if let familyId = game.gameFamilyId {
                groups[familyId, default: []].append(game)
            } else {
                noFamilyGames.append(game)
            }
        }

        var result: [AdminGameGroup] = []

        // Add grouped games
        for (familyId, familyGames) in groups {
            let firstGame = familyGames.first!
            result.append(AdminGameGroup(
                gameFamilyId: familyId,
                title: firstGame.title,
                coverUrl: firstGame.coverUrl,
                games: familyGames.sorted { ($0.platformName ?? "") < ($1.platformName ?? "") }
            ))
        }

        // Add games without family as individual groups
        for game in noFamilyGames {
            result.append(AdminGameGroup(
                gameFamilyId: nil,
                title: game.title,
                coverUrl: game.coverUrl,
                games: [game]
            ))
        }

        // Sort by title
        return result.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
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
                    gameFamilyId
                    title
                    description
                    coverUrl
                    type
                    baseGameFamilyIds
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

    func setPageSize(_ newSize: Int) async {
        pageSize = newSize
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

    func createGameFamily(title: String, description: String?, coverUrl: String?, platformIds: [String], type: GameType = .BASE_GAME, baseGameFamilyIds: [String]? = nil) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation CreateGameFamily($input: CreateGameFamilyInput!) {
            createGameFamily(input: $input) {
                success
                error {
                    code
                    message
                    field
                }
                gameFamilyId
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "platformIds": platformIds,
            "type": type.rawValue
        ]
        if let description = description, !description.isEmpty {
            input["description"] = description
        }
        if let coverUrl = coverUrl, !coverUrl.isEmpty {
            input["coverUrl"] = coverUrl
        }
        if let baseGameFamilyIds = baseGameFamilyIds, !baseGameFamilyIds.isEmpty {
            input["baseGameFamilyIds"] = baseGameFamilyIds
        }

        let variables: [String: Any] = ["input": input]

        do {
            let response: CreateGameFamilyResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.createGameFamily.success {
                await fetchGames(page: 1)
                DispatchQueue.main.async {
                    self.successMessage = "Game created successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = response.createGameFamily.error?.message ?? "Failed to create game"
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

    func createGame(title: String, description: String?, coverUrl: String?, platformId: String, type: GameType = .BASE_GAME, baseGameFamilyIds: [String]? = nil) async -> Bool {
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
        if let baseGameFamilyIds = baseGameFamilyIds, !baseGameFamilyIds.isEmpty {
            input["baseGameFamilyIds"] = baseGameFamilyIds
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

    func addGameToFamily(gameFamilyId: String, platformId: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation AddGameToFamily($input: AddGameToFamilyInput!) {
            addGameToFamily(input: $input) {
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

        let input: [String: Any] = [
            "gameFamilyId": gameFamilyId,
            "platformId": platformId
        ]

        do {
            let response: AddGameToFamilyResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["input": input]
            )
            if response.addGameToFamily.success {
                await fetchGames(page: currentPage)
                DispatchQueue.main.async {
                    self.successMessage = "Platform added successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = response.addGameToFamily.error?.message ?? "Failed to add platform"
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

    func updateGame(id: String, title: String, description: String?, coverUrl: String?, platformId: String, type: GameType = .BASE_GAME, baseGameFamilyIds: [String]? = nil) async -> Bool {
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
        // baseGameFamilyIds - pass the array (empty array clears all base game families)
        if let baseGameFamilyIds = baseGameFamilyIds {
            input["baseGameFamilyIds"] = baseGameFamilyIds
        } else if type == .BASE_GAME {
            // Clear base game families when switching to BASE_GAME
            input["baseGameFamilyIds"] = [String]()
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

    func cloneGameToPlatform(gameId: String, targetPlatformId: String, copyAchievementSets: Bool) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation CloneGameToPlatform($gameId: ID!, $targetPlatformId: ID!, $copyAchievementSets: Boolean) {
            cloneGameToPlatform(gameId: $gameId, targetPlatformId: $targetPlatformId, copyAchievementSets: $copyAchievementSets) {
                success
                game {
                    id
                }
                error {
                    code
                    message
                    field
                }
            }
        }
        """

        let variables: [String: Any] = [
            "gameId": gameId,
            "targetPlatformId": targetPlatformId,
            "copyAchievementSets": copyAchievementSets
        ]

        do {
            let response: CloneGameResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.cloneGameToPlatform.success {
                await fetchGames(page: 1)
                DispatchQueue.main.async {
                    self.successMessage = "Game cloned successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = response.cloneGameToPlatform.error?.message ?? "Failed to clone game"
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

    /// Fetch a single game by ID for editing
    func fetchGame(id: String) async {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.gameToEdit = nil
        }

        // Use the standard game query and map to AdminGameItem
        let query = """
        query GetGame($id: ID!) {
            game(id: $id) {
                id
                gameFamilyId
                title
                description
                coverUrl
                type
                baseGameFamilies {
                    id
                    title
                    slug
                    coverUrl
                    type
                }
                platform {
                    id
                    name
                    slug
                }
            }
        }
        """

        do {
            let response: GameForEditResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["id": id]
            )
            DispatchQueue.main.async {
                if let game = response.game {
                    // Map to AdminGameItem format
                    let baseGameFamilyIds = game.baseGameFamilies?.map { $0.id } ?? []
                    self.gameToEdit = AdminGameItem(
                        id: game.id,
                        gameFamilyId: game.gameFamilyId,
                        title: game.title,
                        description: game.description,
                        coverUrl: game.coverUrl,
                        type: game.type,
                        baseGameFamilyId: baseGameFamilyIds.first,
                        baseGameFamilyIds: baseGameFamilyIds,
                        platformId: game.platform?.id,
                        platformName: game.platform?.name,
                        platformSlug: game.platform?.slug,
                        achievementSetCount: 0
                    )
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
