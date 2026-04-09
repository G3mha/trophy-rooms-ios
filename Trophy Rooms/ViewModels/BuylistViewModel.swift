import Foundation
import Combine

class BuylistViewModel: ObservableObject {
    @Published var buylistItems: [BuylistItem] = []
    @Published var stats: BuylistStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPriority: BuylistPriority?
    @Published var selectedItemType: BuylistItemType?

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

    func fetchBuylist() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetMyBuylist {
            myBuylist {
                id
                userId
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
                addedAt
                updatedAt
            }
        }
        """

        do {
            let response: BuylistResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.buylistItems = response.myBuylist
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func fetchStats() async {
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
            DispatchQueue.main.async {
                self.stats = response.buylistStats
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
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
                await fetchBuylist()
                await fetchStats()
            }
            return response.addToBuylist.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
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
                DispatchQueue.main.async {
                    self.buylistItems.removeAll { $0.id == id }
                }
                await fetchStats()
            }
            return response.removeFromBuylist.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
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
                await fetchBuylist()
                await fetchStats()
            }
            return response.updateBuylistItem.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
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
                DispatchQueue.main.async {
                    self.buylistItems.removeAll { $0.id == id }
                }
                await fetchStats()
            }
            return response.markAsPurchased.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
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
