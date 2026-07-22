import Foundation
import Combine

/// A single cell in the collection grid: either an owned game copy or an
/// owned bundle, so both can live in the same platform groups.
enum CollectionEntry: Identifiable {
    case game(CollectionItem)
    case bundle(AppBundle)

    var id: String {
        switch self {
        case .game(let item): return "game-\(item.id)"
        case .bundle(let bundle): return "bundle-\(bundle.id)"
        }
    }

    var sortTitle: String {
        switch self {
        case .game(let item): return item.game.title
        case .bundle(let bundle): return bundle.name
        }
    }
}

@MainActor
class CollectionViewModel: ObservableObject {
    @Published var collectionItems: [CollectionItem] = []
    @Published var ownedBundles: [AppBundle] = []
    @Published var stats: CollectionStats?
    @Published var isLoading = false
    @Published var hasLoadedOnce = false
    @Published var errorMessage: String?
    @Published var selectedRegion: GameRegion?
    @Published var selectedPlatformId: String?
    @Published var showSealedOnly = false
    @Published var showCompleteOnly = false
    @Published var selectedSortOption: CollectionSortOption = .titleAsc {
        didSet {
            UserDefaults.standard.set(selectedSortOption.rawValue, forKey: "collection_sortOption")
        }
    }
    @Published var groupByPlatform: Bool = false {
        didSet {
            UserDefaults.standard.set(groupByPlatform, forKey: "collection_groupByPlatform")
        }
    }

    init() {
        // Load persisted preferences
        if let sortRaw = UserDefaults.standard.string(forKey: "collection_sortOption"),
           let sortOption = CollectionSortOption(rawValue: sortRaw) {
            self.selectedSortOption = sortOption
        }
        self.groupByPlatform = UserDefaults.standard.bool(forKey: "collection_groupByPlatform")
    }

    var filteredItems: [CollectionItem] {
        var items = collectionItems

        if let region = selectedRegion {
            items = items.filter { $0.region == region }
        }

        if let platformId = selectedPlatformId {
            items = items.filter { $0.platform?.id == platformId }
        }

        if showSealedOnly {
            items = items.filter { $0.isSealed }
        }

        if showCompleteOnly {
            items = items.filter { $0.isComplete }
        }

        return sortItems(items)
    }

    private func sortItems(_ items: [CollectionItem]) -> [CollectionItem] {
        switch selectedSortOption {
        case .titleAsc:
            return items.sorted { $0.game.title.localizedCaseInsensitiveCompare($1.game.title) == .orderedAscending }
        case .titleDesc:
            return items.sorted { $0.game.title.localizedCaseInsensitiveCompare($1.game.title) == .orderedDescending }
        case .dateAddedDesc:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .dateAddedAsc:
            return items.sorted { $0.createdAt < $1.createdAt }
        case .regionAsc:
            return items.sorted { regionOrder($0.region) < regionOrder($1.region) }
        }
    }

    private func regionOrder(_ region: GameRegion) -> Int {
        switch region {
        case .NTSC_U: return 0
        case .PAL: return 1
        case .NTSC_J: return 2
        case .OTHER: return 3
        }
    }

    /// Bundles that pass the active filters. Region/sealed/complete filters
    /// cannot apply to bundles, so bundles are hidden while any is active.
    var filteredBundles: [AppBundle] {
        if selectedRegion != nil || showSealedOnly || showCompleteOnly {
            return []
        }
        var bundles = ownedBundles
        if let platformId = selectedPlatformId {
            bundles = bundles.filter { bundle in
                let owned = bundle.ownedPlatforms ?? []
                if !owned.isEmpty {
                    return owned.contains { $0.id == platformId }
                }
                return bundle.platforms.contains { $0.id == platformId }
            }
        }
        return bundles
    }

    /// Platforms a bundle should be grouped under: the platforms the user
    /// owns it on, else its only available platform, else the "Other" group.
    private func groupPlatforms(for bundle: AppBundle) -> [Platform?] {
        if let owned = bundle.ownedPlatforms, !owned.isEmpty {
            return owned
        }
        if bundle.platforms.count == 1 {
            return [bundle.platforms[0]]
        }
        return [nil]
    }

    private func sortEntries(_ entries: [CollectionEntry]) -> [CollectionEntry] {
        func titleAscending(_ a: CollectionEntry, _ b: CollectionEntry) -> Bool {
            a.sortTitle.localizedCaseInsensitiveCompare(b.sortTitle) == .orderedAscending
        }

        switch selectedSortOption {
        case .titleAsc:
            return entries.sorted(by: titleAscending)
        case .titleDesc:
            return entries.sorted { titleAscending($1, $0) }
        case .dateAddedDesc:
            // Bundles carry no local owned-date, so they sort after games
            return entries.sorted {
                switch ($0, $1) {
                case (.game(let a), .game(let b)): return a.createdAt > b.createdAt
                case (.game, .bundle): return true
                case (.bundle, .game): return false
                case (.bundle, .bundle): return titleAscending($0, $1)
                }
            }
        case .dateAddedAsc:
            return entries.sorted {
                switch ($0, $1) {
                case (.game(let a), .game(let b)): return a.createdAt < b.createdAt
                case (.game, .bundle): return true
                case (.bundle, .game): return false
                case (.bundle, .bundle): return titleAscending($0, $1)
                }
            }
        case .regionAsc:
            return entries.sorted {
                switch ($0, $1) {
                case (.game(let a), .game(let b)): return regionOrder(a.region) < regionOrder(b.region)
                case (.game, .bundle): return true
                case (.bundle, .game): return false
                case (.bundle, .bundle): return titleAscending($0, $1)
                }
            }
        }
    }

    /// Filtered games and owned bundles merged into one sorted list
    var flatEntries: [CollectionEntry] {
        sortEntries(filteredItems.map { .game($0) } + filteredBundles.map { .bundle($0) })
    }

    /// Groups filtered games and owned bundles together by platform
    var groupedEntries: [(platform: Platform?, entries: [CollectionEntry])] {
        var groups: [String: (platform: Platform?, entries: [CollectionEntry])] = [:]

        func append(_ entry: CollectionEntry, under platform: Platform?) {
            let key = platform?.id ?? "other"
            if groups[key] != nil {
                groups[key]!.entries.append(entry)
            } else {
                groups[key] = (platform: platform, entries: [entry])
            }
        }

        for item in filteredItems {
            append(.game(item), under: item.platform)
        }
        for bundle in filteredBundles {
            for platform in groupPlatforms(for: bundle) {
                append(.bundle(bundle), under: platform)
            }
        }

        return groups.values
            .map { (platform: $0.platform, entries: sortEntries($0.entries)) }
            .sorted { lhs, rhs in
                if lhs.platform == nil { return false }
                if rhs.platform == nil { return true }
                return (lhs.platform?.name ?? "") < (rhs.platform?.name ?? "")
            }
    }

    // Get unique platforms from collection items
    var availablePlatforms: [Platform] {
        var seen = Set<String>()
        var platforms: [Platform] = []
        for item in collectionItems {
            if let platform = item.platform, !seen.contains(platform.id) {
                seen.insert(platform.id)
                platforms.append(platform)
            }
        }
        return platforms.sorted { $0.name < $1.name }
    }

    func fetchCollection(forceRefresh: Bool = false) async {
        // Load from cache immediately (no loading state)
        if !forceRefresh, let cached: CollectionWithStatsResponse = await CacheManager.shared.get(.collection) {
            collectionItems = cached.myCollection
            stats = cached.collectionStats
            ownedBundles = cached.myOwnedBundles ?? []
            // If we have cached data and not forcing refresh, we're done
            if !collectionItems.isEmpty && hasLoadedOnce {
                return
            }
        }

        // Show loading only if no data at all (first load with no cache)
        if collectionItems.isEmpty && !hasLoadedOnce {
            isLoading = true
        }
        errorMessage = nil

        let query = """
        query GetMyCollection {
            myCollection {
                id
                gameId
                game { id title coverUrl }
                platform { id name slug }
                gameVersion { id name }
                gameVersionId
                isDigital
                hasDisc
                hasBox
                hasManual
                hasExtras
                isSealed
                region
                notes
                createdAt
                updatedAt
            }
            collectionStats {
                totalItems
                sealedCount
                completeCount
                byRegion {
                    region
                    count
                }
            }
            myOwnedBundles {
                id
                name
                slug
                type
                coverUrl
                platforms { id name slug }
                ownedPlatforms { id name slug }
                platformCount
                gameFamilyCount
                dlcCount
            }
        }
        """

        do {
            let response: CollectionWithStatsResponse = try await NetworkService.shared.fetch(query: query)
            await CacheManager.shared.set(.collection, value: response)
            collectionItems = response.myCollection
            stats = response.collectionStats
            ownedBundles = response.myOwnedBundles ?? []
            isLoading = false
            hasLoadedOnce = true
        } catch is CancellationError {
            isLoading = false
            hasLoadedOnce = true
        } catch let error as NSError where error.code == NSURLErrorCancelled {
            isLoading = false
            hasLoadedOnce = true
        } catch {
            // Only show error if no cached data
            if collectionItems.isEmpty {
                errorMessage = error.localizedDescription
            }
            isLoading = false
            hasLoadedOnce = true
        }
    }

    func removeFromCollection(id: String) async -> Bool {
        let mutation = """
        mutation RemoveFromCollection($id: ID!) {
            removeFromCollection(id: $id) {
                success
            }
        }
        """

        do {
            let response: RemoveFromCollectionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            if response.removeFromCollection.success {
                await CacheInvalidation.forCollectionChange()
                collectionItems.removeAll { $0.id == id }
                // Update stats
                if var currentStats = stats {
                    currentStats = CollectionStats(
                        totalItems: currentStats.totalItems - 1,
                        sealedCount: currentStats.sealedCount,
                        completeCount: currentStats.completeCount,
                        byRegion: currentStats.byRegion
                    )
                    stats = currentStats
                }
            }
            return response.removeFromCollection.success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

// Response type for combined query
struct CollectionWithStatsResponse: Codable {
    let myCollection: [CollectionItem]
    let collectionStats: CollectionStats
    let myOwnedBundles: [AppBundle]?
}
