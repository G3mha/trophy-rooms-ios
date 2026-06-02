import Foundation

/// Centralized cache invalidation helpers that group related cache key invalidations
enum CacheInvalidation {

    // MARK: - Single Domain Invalidations

    /// Invalidate library cache when game status changes
    static func forLibraryChange() async {
        await CacheManager.shared.invalidate(.library)
    }

    /// Invalidate collection cache when collection items change
    static func forCollectionChange() async {
        await CacheManager.shared.invalidate(.collection, .collectionStats)
    }

    /// Invalidate buylist cache when buylist items change
    static func forBuylistChange() async {
        await CacheManager.shared.invalidate(.buylist, .buylistStats)
    }

    /// Invalidate sell list cache when sell list items change
    static func forSellListChange() async {
        await CacheManager.shared.invalidate(.sellList, .sellListStats)
    }

    /// Invalidate owned bundles cache
    static func forOwnedBundlesChange() async {
        await CacheManager.shared.invalidate(.ownedBundles)
    }

    // MARK: - Cross-Domain Invalidations

    /// Invalidate caches when an item is marked as purchased from buylist
    /// This affects: buylist (item removed), collection (item added), library (status may change)
    static func forMarkAsPurchased() async {
        await forBuylistChange()
        await forCollectionChange()
        await forLibraryChange()
    }

    /// Invalidate caches when an item is marked as sold from sell list
    /// This affects: sell list (status changes), collection (item may be removed)
    static func forMarkAsSold() async {
        await forSellListChange()
        await forCollectionChange()
    }

    /// Invalidate caches when bundle ownership changes
    /// This affects: owned bundles list, collection stats
    static func forBundleOwnershipChange() async {
        await forOwnedBundlesChange()
        await forCollectionChange()
    }

    // MARK: - Detail Page Invalidations

    /// Invalidate a specific game's cache
    static func forGame(id: String) async {
        await CacheManager.shared.invalidate(.game(id: id))
    }

    /// Invalidate a specific bundle's cache
    static func forBundle(id: String) async {
        await CacheManager.shared.invalidate(.bundle(id: id))
    }

    /// Invalidate collection items for a specific game
    static func forCollectionForGame(gameId: String) async {
        await CacheManager.shared.invalidate(.collectionForGame(gameId: gameId))
    }
}
