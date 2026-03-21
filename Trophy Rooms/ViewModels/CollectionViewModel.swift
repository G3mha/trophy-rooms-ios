import Foundation
import Combine

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

        return items
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

    func fetchCollection() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetMyCollection {
            myCollection {
                id
                gameId
                game { id title coverUrl }
                platform { id name slug }
                gameVersion { id name }
                gameVersionId
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
            DispatchQueue.main.async {
                self.collectionItems = response.myCollection
                self.stats = response.collectionStats
                self.isLoading = false
                self.hasLoadedOnce = true
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.hasLoadedOnce = true
            }
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
                DispatchQueue.main.async {
                    self.collectionItems.removeAll { $0.id == id }
                    // Update stats
                    if var currentStats = self.stats {
                        currentStats = CollectionStats(
                            totalItems: currentStats.totalItems - 1,
                            sealedCount: currentStats.sealedCount,
                            completeCount: currentStats.completeCount,
                            byRegion: currentStats.byRegion
                        )
                        self.stats = currentStats
                    }
                }
            }
            return response.removeFromCollection.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
}

// Response type for combined query
struct CollectionWithStatsResponse: Decodable {
    let myCollection: [CollectionItem]
    let collectionStats: CollectionStats
}
