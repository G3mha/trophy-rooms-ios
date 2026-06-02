import Foundation
import Combine

@MainActor
class SellListViewModel: ObservableObject {
    @Published var sellListItems: [SellListItem] = []
    @Published var stats: SellListStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCondition: ItemCondition?
    @Published var showSoldItems: Bool = false
    @Published var selectedSortOption: SellListSortOption = .dateAddedDesc {
        didSet {
            UserDefaults.standard.set(selectedSortOption.rawValue, forKey: "sellList_sortOption")
        }
    }
    @Published var groupByPlatform: Bool = false {
        didSet {
            UserDefaults.standard.set(groupByPlatform, forKey: "sellList_groupByPlatform")
        }
    }
    var hasLoadedOnce = false

    init() {
        // Load persisted preferences
        if let sortRaw = UserDefaults.standard.string(forKey: "sellList_sortOption"),
           let sortOption = SellListSortOption(rawValue: sortRaw) {
            self.selectedSortOption = sortOption
        }
        self.groupByPlatform = UserDefaults.standard.bool(forKey: "sellList_groupByPlatform")
    }

    var filteredItems: [SellListItem] {
        var items = sellListItems

        // Filter by status (show active or active + sold)
        if !showSoldItems {
            items = items.filter { $0.status == .ACTIVE }
        } else {
            items = items.filter { $0.status == .ACTIVE || $0.status == .SOLD }
        }

        // Filter by condition
        if let condition = selectedCondition {
            items = items.filter { $0.condition == condition }
        }

        return items
    }

    var conditionCounts: [ItemCondition: Int] {
        var counts: [ItemCondition: Int] = [:]
        for item in sellListItems where item.status == .ACTIVE {
            counts[item.condition, default: 0] += 1
        }
        return counts
    }

    /// Groups filtered items by platform
    var groupedItems: [(platform: SellListPlatform?, items: [SellListItem])] {
        var groups: [String: (platform: SellListPlatform?, items: [SellListItem])] = [:]

        for item in filteredItems {
            let key = item.displayPlatform?.id ?? "other"
            if groups[key] != nil {
                groups[key]!.items.append(item)
            } else {
                groups[key] = (platform: item.displayPlatform, items: [item])
            }
        }

        // Sort groups: platforms with names first, then "Other" (nil platform)
        return groups.values.sorted { lhs, rhs in
            if lhs.platform == nil { return false }
            if rhs.platform == nil { return true }
            return (lhs.platform?.name ?? "") < (rhs.platform?.name ?? "")
        }
    }

    /// Available platforms from current sell list items
    var availablePlatforms: [SellListPlatform] {
        var platforms: [SellListPlatform] = []
        var seen: Set<String> = []

        for item in sellListItems where item.status == .ACTIVE {
            if let platform = item.displayPlatform, !seen.contains(platform.id) {
                platforms.append(platform)
                seen.insert(platform.id)
            }
        }

        return platforms.sorted { $0.name < $1.name }
    }

    func fetchSellList(forceRefresh: Bool = false) async {
        // Load from cache immediately (no loading state)
        if !forceRefresh, let cached: SellListResponse = await CacheManager.shared.get(.sellList) {
            sellListItems = cached.mySellList
            // If we have cached data and not forcing refresh, we're done
            if !sellListItems.isEmpty && hasLoadedOnce {
                return
            }
        }

        // Show loading only if no data at all (first load with no cache)
        if sellListItems.isEmpty && !hasLoadedOnce {
            isLoading = true
        }
        errorMessage = nil

        let query = """
        query GetMySellList($orderBy: SellListOrderBy) {
            mySellList(orderBy: $orderBy) {
                id
                collectionItemId
                askingPrice
                condition
                conditionNotes
                listingUrl
                notes
                status
                salePrice
                soldAt
                displayTitle
                displayCoverUrl
                displayPlatform {
                    id
                    name
                    slug
                }
                addedAt
                updatedAt
            }
        }
        """

        do {
            let response: SellListResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["orderBy": selectedSortOption.rawValue]
            )
            await CacheManager.shared.set(.sellList, value: response)
            sellListItems = response.mySellList
            hasLoadedOnce = true
        } catch {
            // Only show error if no data at all
            if sellListItems.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func fetchStats(forceRefresh: Bool = false) async {
        // Load from cache immediately
        if !forceRefresh, let cached: SellListStatsResponse = await CacheManager.shared.get(.sellListStats) {
            stats = cached.sellListStats
            // If we have cached stats and not forcing refresh, we're done
            if stats != nil && hasLoadedOnce {
                return
            }
        }

        let query = """
        query GetSellListStats {
            sellListStats {
                activeCount
                soldCount
                totalAskingValue
                totalSoldValue
            }
        }
        """

        do {
            let response: SellListStatsResponse = try await NetworkService.shared.fetch(query: query)
            await CacheManager.shared.set(.sellListStats, value: response)
            stats = response.sellListStats
        } catch {
            // Only show error if no stats at all
            if stats == nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    func addToSellList(
        collectionItemId: String,
        askingPrice: Double? = nil,
        condition: ItemCondition = .GOOD,
        conditionNotes: String? = nil,
        listingUrl: String? = nil,
        notes: String? = nil
    ) async -> Bool {
        let mutation = """
        mutation AddToSellList($input: AddToSellListInput!) {
            addToSellList(input: $input) {
                success
                sellListItem {
                    id
                }
            }
        }
        """

        var input: [String: Any] = [
            "collectionItemId": collectionItemId,
            "condition": condition.rawValue
        ]
        if let askingPrice = askingPrice { input["askingPrice"] = askingPrice }
        if let conditionNotes = conditionNotes { input["conditionNotes"] = conditionNotes }
        if let listingUrl = listingUrl { input["listingUrl"] = listingUrl }
        if let notes = notes { input["notes"] = notes }

        do {
            let response: AddToSellListResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["input": input]
            )
            if response.addToSellList.success {
                await CacheInvalidation.forSellListChange()
                await fetchSellList(forceRefresh: true)
                await fetchStats(forceRefresh: true)
            }
            return response.addToSellList.success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateSellListItem(
        id: String,
        askingPrice: Double? = nil,
        condition: ItemCondition? = nil,
        conditionNotes: String? = nil,
        listingUrl: String? = nil,
        notes: String? = nil
    ) async -> Bool {
        let mutation = """
        mutation UpdateSellListItem($id: ID!, $input: UpdateSellListItemInput!) {
            updateSellListItem(id: $id, input: $input) {
                success
                sellListItem {
                    id
                }
            }
        }
        """

        var input: [String: Any] = [:]
        if let askingPrice = askingPrice { input["askingPrice"] = askingPrice }
        if let condition = condition { input["condition"] = condition.rawValue }
        if let conditionNotes = conditionNotes { input["conditionNotes"] = conditionNotes }
        if let listingUrl = listingUrl { input["listingUrl"] = listingUrl }
        if let notes = notes { input["notes"] = notes }

        do {
            let response: UpdateSellListItemResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id, "input": input]
            )
            if response.updateSellListItem.success {
                await CacheInvalidation.forSellListChange()
                await fetchSellList(forceRefresh: true)
                await fetchStats(forceRefresh: true)
            }
            return response.updateSellListItem.success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func removeFromSellList(id: String) async -> Bool {
        let mutation = """
        mutation RemoveFromSellList($id: ID!) {
            removeFromSellList(id: $id) {
                success
            }
        }
        """

        do {
            let response: RemoveFromSellListResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            if response.removeFromSellList.success {
                await CacheInvalidation.forSellListChange()
                sellListItems.removeAll { $0.id == id }
                await fetchStats(forceRefresh: true)
            }
            return response.removeFromSellList.success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func markAsSold(
        id: String,
        salePrice: Double,
        soldAt: Date? = nil
    ) async -> Bool {
        let mutation = """
        mutation MarkAsSold($id: ID!, $input: MarkAsSoldInput!) {
            markAsSold(id: $id, input: $input) {
                success
            }
        }
        """

        var input: [String: Any] = ["salePrice": salePrice]
        if let soldAt = soldAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            input["soldAt"] = formatter.string(from: soldAt)
        }

        do {
            let response: MarkAsSoldResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id, "input": input]
            )
            if response.markAsSold.success {
                await CacheInvalidation.forMarkAsSold()
                await fetchSellList(forceRefresh: true)
                await fetchStats(forceRefresh: true)
            }
            return response.markAsSold.success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func markAsSoldAndRemoveFromCollection(
        id: String,
        salePrice: Double,
        soldAt: Date? = nil
    ) async -> Bool {
        let mutation = """
        mutation MarkAsSoldAndRemoveFromCollection($id: ID!, $input: MarkAsSoldInput!) {
            markAsSoldAndRemoveFromCollection(id: $id, input: $input) {
                success
            }
        }
        """

        var input: [String: Any] = ["salePrice": salePrice]
        if let soldAt = soldAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            input["soldAt"] = formatter.string(from: soldAt)
        }

        do {
            let response: MarkAsSoldAndRemoveFromCollectionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id, "input": input]
            )
            if response.markAsSoldAndRemoveFromCollection.success {
                // This affects both sell list and collection
                await CacheInvalidation.forMarkAsSold()
                await fetchSellList(forceRefresh: true)
                await fetchStats(forceRefresh: true)
            }
            return response.markAsSoldAndRemoveFromCollection.success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func isInSellList(collectionItemId: String) async -> Bool {
        let query = """
        query IsInSellList($collectionItemId: ID!) {
            isInSellList(collectionItemId: $collectionItemId)
        }
        """

        do {
            let response: IsInSellListResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["collectionItemId": collectionItemId]
            )
            return response.isInSellList
        } catch {
            return false
        }
    }
}
