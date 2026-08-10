import Foundation
import Combine

@MainActor
class BuylistViewModel: ObservableObject {
    @Published var buylistItems: [BuylistItem] = []
    @Published var stats: BuylistStats?
    /// Database user id - the public share URL is keyed by it, not the auth id
    @Published var publicUserId: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPriority: BuylistPriority?
    @Published var selectedItemType: BuylistItemType?
    @Published var selectedSortOption: BuylistSortOption = .priorityDesc {
        didSet {
            UserDefaults.standard.set(selectedSortOption.rawValue, forKey: "buylist_sortOption")
        }
    }
    @Published var groupByPlatform: Bool = false {
        didSet {
            UserDefaults.standard.set(groupByPlatform, forKey: "buylist_groupByPlatform")
        }
    }
    var hasLoadedOnce = false

    init() {
        // Load persisted preferences
        if let sortRaw = UserDefaults.standard.string(forKey: "buylist_sortOption"),
           let sortOption = BuylistSortOption(rawValue: sortRaw) {
            self.selectedSortOption = sortOption
        }
        self.groupByPlatform = UserDefaults.standard.bool(forKey: "buylist_groupByPlatform")
    }

    var filteredItems: [BuylistItem] {
        var items = buylistItems

        if let priority = selectedPriority {
            items = items.filter { $0.priority == priority }
        }

        if let itemType = selectedItemType {
            items = items.filter { $0.itemType == itemType }
        }

        return items
    }

    var priorityCounts: [BuylistPriority: Int] {
        var counts: [BuylistPriority: Int] = [:]
        for item in buylistItems {
            counts[item.priority, default: 0] += 1
        }
        return counts
    }

    var itemTypeCounts: [BuylistItemType: Int] {
        var counts: [BuylistItemType: Int] = [:]
        for item in buylistItems {
            counts[item.itemType, default: 0] += 1
        }
        return counts
    }

    /// Groups filtered items by platform
    var groupedItems: [(platform: BuylistPlatform?, items: [BuylistItem])] {
        var groups: [String: (platform: BuylistPlatform?, items: [BuylistItem])] = [:]

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

    /// Available platforms from current buylist items
    var availablePlatforms: [BuylistPlatform] {
        var platforms: [BuylistPlatform] = []
        var seen: Set<String> = []

        for item in buylistItems {
            if let platform = item.displayPlatform, !seen.contains(platform.id) {
                platforms.append(platform)
                seen.insert(platform.id)
            }
        }

        return platforms.sorted { $0.name < $1.name }
    }

    /// Count of items per platform
    var platformCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for item in buylistItems {
            let key = item.displayPlatform?.id ?? "other"
            counts[key, default: 0] += 1
        }
        return counts
    }

    func fetchPublicUserId() async {
        guard publicUserId == nil else { return }

        let query = """
        query GetMyPublicId {
            me {
                id
            }
        }
        """

        if let response: MeIdResponse = try? await NetworkService.shared.fetch(query: query) {
            publicUserId = response.me?.id
        }
    }

    private struct MeIdResponse: Codable {
        let me: MeId?

        struct MeId: Codable {
            let id: String
        }
    }

    func fetchBuylist(forceRefresh: Bool = false) async {
        // Load from cache immediately (no loading state)
        if !forceRefresh, let cached: BuylistResponse = await CacheManager.shared.get(.buylist) {
            buylistItems = cached.myBuylist
            // If we have cached data and not forcing refresh, we're done
            if !buylistItems.isEmpty && hasLoadedOnce {
                return
            }
        }

        // Show loading only if no data at all (first load with no cache)
        if buylistItems.isEmpty && !hasLoadedOnce {
            isLoading = true
        }
        errorMessage = nil

        let query = """
        query GetMyBuylist($orderBy: BuylistOrderBy) {
            myBuylist(orderBy: $orderBy) {
                id
                gameId
                gameVersionId
                dlcId
                bundleId
                priority
                notes
                estimatedPrice
                itemType
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
            let response: BuylistResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["orderBy": selectedSortOption.rawValue]
            )
            await CacheManager.shared.set(.buylist, value: response)
            buylistItems = response.myBuylist
            hasLoadedOnce = true
        } catch {
            // Only show error if no data at all
            if buylistItems.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func fetchStats(forceRefresh: Bool = false) async {
        // Load from cache immediately
        if !forceRefresh, let cached: BuylistStatsResponse = await CacheManager.shared.get(.buylistStats) {
            stats = cached.buylistStats
            // If we have cached stats and not forcing refresh, we're done
            if stats != nil && hasLoadedOnce {
                return
            }
        }

        let query = """
        query GetBuylistStats {
            buylistStats {
                totalItems
                totalEstimatedCost
                highPriorityCount
                mediumPriorityCount
                lowPriorityCount
                gameCount
                dlcCount
                bundleCount
            }
        }
        """

        do {
            let response: BuylistStatsResponse = try await NetworkService.shared.fetch(query: query)
            await CacheManager.shared.set(.buylistStats, value: response)
            stats = response.buylistStats
        } catch {
            // Only show error if no stats at all
            if stats == nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    func addToBuylist(
        gameId: String? = nil,
        gameVersionId: String? = nil,
        dlcId: String? = nil,
        bundleId: String? = nil,
        priority: BuylistPriority = .MEDIUM,
        notes: String? = nil,
        estimatedPrice: Double? = nil
    ) async -> Bool {
        let mutation = """
        mutation AddToBuylist($input: AddToBuylistInput!) {
            addToBuylist(input: $input) {
                success
                buylistItem {
                    id
                }
            }
        }
        """

        var input: [String: Any] = ["priority": priority.rawValue]
        if let gameId = gameId { input["gameId"] = gameId }
        if let gameVersionId = gameVersionId { input["gameVersionId"] = gameVersionId }
        if let dlcId = dlcId { input["dlcId"] = dlcId }
        if let bundleId = bundleId { input["bundleId"] = bundleId }
        if let notes = notes { input["notes"] = notes }
        if let estimatedPrice = estimatedPrice { input["estimatedPrice"] = estimatedPrice }

        do {
            let response: AddToBuylistResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["input": input]
            )
            if response.addToBuylist.success {
                await CacheInvalidation.forBuylistChange()
                await fetchBuylist(forceRefresh: true)
                await fetchStats(forceRefresh: true)
            }
            return response.addToBuylist.success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func removeFromBuylist(id: String) async -> Bool {
        let mutation = """
        mutation RemoveFromBuylist($id: ID!) {
            removeFromBuylist(id: $id) {
                success
            }
        }
        """

        do {
            let response: RemoveFromBuylistResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            if response.removeFromBuylist.success {
                await CacheInvalidation.forBuylistChange()
                buylistItems.removeAll { $0.id == id }
                await fetchStats(forceRefresh: true)
            }
            return response.removeFromBuylist.success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updateBuylistItem(
        id: String,
        priority: BuylistPriority? = nil,
        notes: String? = nil,
        estimatedPrice: Double? = nil,
        gameVersionId: String? = nil
    ) async -> Bool {
        let mutation = """
        mutation UpdateBuylistItem($id: ID!, $input: UpdateBuylistItemInput!) {
            updateBuylistItem(id: $id, input: $input) {
                success
                buylistItem {
                    id
                }
            }
        }
        """

        var input: [String: Any] = [:]
        if let priority = priority { input["priority"] = priority.rawValue }
        if let notes = notes { input["notes"] = notes }
        if let estimatedPrice = estimatedPrice { input["estimatedPrice"] = estimatedPrice }
        if let gameVersionId = gameVersionId { input["gameVersionId"] = gameVersionId }

        do {
            let response: UpdateBuylistItemResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id, "input": input]
            )
            if response.updateBuylistItem.success {
                await CacheInvalidation.forBuylistChange()
                await fetchBuylist(forceRefresh: true)
                await fetchStats(forceRefresh: true)
            }
            return response.updateBuylistItem.success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func markAsPurchased(
        id: String,
        platformId: String? = nil,
        purchasePrice: Double? = nil,
        purchasedAt: Date? = nil
    ) async -> Bool {
        let mutation = """
        mutation MarkAsPurchased($id: ID!, $platformId: ID, $purchasePrice: Float, $purchasedAt: DateTime) {
            markAsPurchased(id: $id, platformId: $platformId, purchasePrice: $purchasePrice, purchasedAt: $purchasedAt) {
                success
            }
        }
        """

        var variables: [String: Any] = ["id": id]
        if let platformId = platformId {
            variables["platformId"] = platformId
        }
        if let purchasePrice = purchasePrice {
            variables["purchasePrice"] = purchasePrice
        }
        if let purchasedAt = purchasedAt {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            variables["purchasedAt"] = formatter.string(from: purchasedAt)
        }

        do {
            let response: MarkAsPurchasedResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.markAsPurchased.success {
                // Mark as purchased affects buylist, collection, and library
                await CacheInvalidation.forMarkAsPurchased()
                buylistItems.removeAll { $0.id == id }
                await fetchStats(forceRefresh: true)
            }
            return response.markAsPurchased.success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func isInBuylist(gameId: String? = nil, dlcId: String? = nil, bundleId: String? = nil) async -> Bool {
        let query = """
        query IsInBuylist($gameId: ID, $dlcId: ID, $bundleId: ID) {
            isInBuylist(gameId: $gameId, dlcId: $dlcId, bundleId: $bundleId)
        }
        """

        var variables: [String: Any] = [:]
        if let gameId = gameId { variables["gameId"] = gameId }
        if let dlcId = dlcId { variables["dlcId"] = dlcId }
        if let bundleId = bundleId { variables["bundleId"] = bundleId }

        do {
            let response: IsInBuylistResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: variables
            )
            return response.isInBuylist
        } catch {
            return false
        }
    }
}
