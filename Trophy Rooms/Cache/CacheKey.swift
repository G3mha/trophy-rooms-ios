import Foundation

/// Type-safe cache keys for all cacheable data
enum CacheKey: Hashable {
    // MARK: - List Data
    case library
    case collection
    case collectionStats
    case buylist
    case buylistStats
    case sellList
    case sellListStats
    case ownedBundles

    // MARK: - Detail Data (with ID)
    case game(id: String)
    case bundle(id: String)
    case gameVersions(gameId: String)
    case collectionForGame(gameId: String)

    /// String representation for disk storage and memory cache keys
    var stringValue: String {
        switch self {
        case .library:
            return "library"
        case .collection:
            return "collection"
        case .collectionStats:
            return "collection_stats"
        case .buylist:
            return "buylist"
        case .buylistStats:
            return "buylist_stats"
        case .sellList:
            return "sell_list"
        case .sellListStats:
            return "sell_list_stats"
        case .ownedBundles:
            return "owned_bundles"
        case .game(let id):
            return "game_\(id)"
        case .bundle(let id):
            return "bundle_\(id)"
        case .gameVersions(let gameId):
            return "game_versions_\(gameId)"
        case .collectionForGame(let gameId):
            return "collection_for_game_\(gameId)"
        }
    }
}
