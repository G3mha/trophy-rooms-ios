import Foundation
import Combine

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var libraryItems: [LibraryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedStatus: GameStatus?
    @Published var selectedPlatformId: String?
    var hasLoadedOnce = false
    @Published var selectedSortOption: LibrarySortOption = .titleAsc {
        didSet {
            UserDefaults.standard.set(selectedSortOption.rawValue, forKey: "library_sortOption")
        }
    }
    @Published var groupByPlatform: Bool = false {
        didSet {
            UserDefaults.standard.set(groupByPlatform, forKey: "library_groupByPlatform")
        }
    }

    init() {
        // Load persisted preferences
        if let sortRaw = UserDefaults.standard.string(forKey: "library_sortOption"),
           let sortOption = LibrarySortOption(rawValue: sortRaw) {
            self.selectedSortOption = sortOption
        }
        self.groupByPlatform = UserDefaults.standard.bool(forKey: "library_groupByPlatform")
    }

    var filteredItems: [LibraryItem] {
        var items = libraryItems

        if let status = selectedStatus {
            items = items.filter { $0.status == status }
        }

        if let platformId = selectedPlatformId {
            items = items.filter { $0.platformId == platformId }
        }

        return sortItems(items)
    }

    private func sortItems(_ items: [LibraryItem]) -> [LibraryItem] {
        switch selectedSortOption {
        case .titleAsc:
            return items.sorted { $0.gameTitle.localizedCaseInsensitiveCompare($1.gameTitle) == .orderedAscending }
        case .titleDesc:
            return items.sorted { $0.gameTitle.localizedCaseInsensitiveCompare($1.gameTitle) == .orderedDescending }
        case .statusAsc:
            return items.sorted { statusOrder($0.status) < statusOrder($1.status) }
        case .statusDesc:
            return items.sorted { statusOrder($0.status) > statusOrder($1.status) }
        case .dateAddedDesc:
            return items.sorted { $0.addedAt > $1.addedAt }
        case .dateAddedAsc:
            return items.sorted { $0.addedAt < $1.addedAt }
        }
    }

    private func statusOrder(_ status: GameStatus) -> Int {
        switch status {
        case .BACKLOG: return 0
        case .PLAYING: return 1
        case .PAUSED: return 2
        case .COMPLETED: return 3
        case .DROPPED: return 4
        }
    }

    /// Groups filtered items by platform
    var groupedItems: [(platform: (id: String, name: String, slug: String?)?, items: [LibraryItem])] {
        var groups: [String: (platform: (id: String, name: String, slug: String?)?, items: [LibraryItem])] = [:]

        for item in filteredItems {
            let key = item.platformId ?? "other"
            if groups[key] != nil {
                groups[key]!.items.append(item)
            } else {
                let platform: (id: String, name: String, slug: String?)? = item.platformId != nil
                    ? (id: item.platformId!, name: item.platformName ?? "Unknown", slug: item.platformSlug)
                    : nil
                groups[key] = (platform: platform, items: [item])
            }
        }

        return groups.values.sorted { lhs, rhs in
            if lhs.platform == nil { return false }
            if rhs.platform == nil { return true }
            return (lhs.platform?.name ?? "") < (rhs.platform?.name ?? "")
        }
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

    func fetchLibrary(forceRefresh: Bool = false) async {
        // Load from cache immediately (no loading state)
        if !forceRefresh, let cached: LibraryResponse = await CacheManager.shared.get(.library) {
            libraryItems = cached.myGamesByStatus
            // If we have cached data and not forcing refresh, we're done
            if !libraryItems.isEmpty && hasLoadedOnce {
                return
            }
        }

        // Show loading only if no data at all (first load with no cache)
        if libraryItems.isEmpty && !hasLoadedOnce {
            isLoading = true
        }
        errorMessage = nil

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
                bundles { id name coverUrl }
                addedAt
                updatedAt
            }
        }
        """

        do {
            let response: LibraryResponse = try await NetworkService.shared.fetch(query: query)
            await CacheManager.shared.set(.library, value: response)
            libraryItems = response.myGamesByStatus
            hasLoadedOnce = true
        } catch is CancellationError {
            isLoading = false
            hasLoadedOnce = true
        } catch let error as NSError where error.code == NSURLErrorCancelled {
            isLoading = false
            hasLoadedOnce = true
        } catch {
            // Only show error if no cached data
            if libraryItems.isEmpty {
                errorMessage = error.localizedDescription
            }
            hasLoadedOnce = true
        }
        isLoading = false
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
                await CacheInvalidation.forLibraryChange()
                await fetchLibrary(forceRefresh: true)
            }
            return response.setGameStatus.success
        } catch {
            errorMessage = error.localizedDescription
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
                await CacheInvalidation.forLibraryChange()
                libraryItems.removeAll { $0.gameId == gameId }
            }
            return response.clearGameStatus.success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
