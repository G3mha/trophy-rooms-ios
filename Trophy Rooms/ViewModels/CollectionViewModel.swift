import Foundation
import Combine

@MainActor
class CollectionViewModel: ObservableObject {
    @Published var collectionItems: [CollectionItem] = []
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
            return items.sorted { $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending }
        case .titleDesc:
            return items.sorted { $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedDescending }
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

    /// Groups filtered items (games and bundles alike) by platform
    var groupedItems: [(platform: Platform?, items: [CollectionItem])] {
        var groups: [String: (platform: Platform?, items: [CollectionItem])] = [:]

        for item in filteredItems {
            let key = item.platform?.id ?? "other"
            if groups[key] != nil {
                groups[key]!.items.append(item)
            } else {
                groups[key] = (platform: item.platform, items: [item])
            }
        }

        return groups.values.sorted { lhs, rhs in
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
                bundleId
                bundle { id name coverUrl gameFamilies { id title coverUrl } }
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
        }
        """

        do {
            let response: CollectionWithStatsResponse = try await NetworkService.shared.fetch(query: query)
            await CacheManager.shared.set(.collection, value: response)
            collectionItems = response.myCollection
            stats = response.collectionStats
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
