import Foundation

// MARK: - Achievement Tier

enum AchievementTier: String, Codable, CaseIterable {
    case BRONZE
    case SILVER
    case GOLD
}

// MARK: - Platform

struct Platform: Identifiable, Decodable {
    let id: String
    let name: String
    let slug: String
}

// MARK: - Game Models

struct GameSummary: Identifiable, Decodable {
    let id: String
    let title: String
    let description: String?
    let coverUrl: String?
    let platform: Platform?
    let achievementSetCount: Int
    let achievementCount: Int
    let trophyCount: Int
}

struct AchievementSet: Identifiable, Decodable {
    let id: String
    let title: String
    let type: String
    let visibility: String
    let createdByUserId: String?
    let achievements: [Achievement]
}

struct Achievement: Identifiable, Decodable {
    let id: String
    let title: String
    let description: String?
    let iconUrl: String?
    let points: Int
    let tier: AchievementTier?
    let isCompleted: Bool?
    let userCount: Int?
    let achievementSetId: String
}

struct GameDetail: Identifiable, Decodable {
    let id: String
    let title: String
    let description: String?
    let coverUrl: String?
    let trophyCount: Int
    let releaseDate: String?
    let developer: String?
    let publisher: String?
    let genre: String?
    let esrbRating: String?
    let screenshots: [String]?
    let platform: Platform?
    let achievementSets: [AchievementSet]
}

// MARK: - Leaderboard Models

struct LeaderboardEntry: Codable, Identifiable {
    let rank: Int
    let userId: String
    let userName: String?
    let userEmail: String
    let value: Int
    let secondaryValue: Int?

    var id: String { "\(rank)-\(userId)" }
}

struct FastestCompletionEntry: Codable, Identifiable {
    let rank: Int
    let userId: String
    let userName: String?
    let userEmail: String
    let gameId: String
    let gameTitle: String
    let completionTimeHours: Float
    let completedAt: String

    var id: String { "\(rank)-\(userId)-\(gameId)" }
}

// MARK: - Activity Models

struct ActivityEntry: Codable, Identifiable {
    let id: String
    let type: String
    let userId: String
    let userName: String?
    let userEmail: String
    let achievementId: String?
    let achievementTitle: String?
    let achievementTier: AchievementTier?
    let achievementPoints: Int?
    let gameId: String
    let gameTitle: String
    let platformName: String?
    let platformSlug: String?
    let earnedAt: String
}

// MARK: - Wishlist Models

struct WishlistItem: Codable, Identifiable {
    let id: String
    let gameId: String
    let gameTitle: String
    let gameCoverUrl: String?
    let gameDescription: String?
    let achievementCount: Int
    let platformId: String?
    let platformName: String?
    let platformSlug: String?
    let addedAt: String
}

// MARK: - Library Models

enum GameStatus: String, Codable, CaseIterable {
    case WISHLIST
    case BACKLOG
    case PLAYING
    case PAUSED
    case COMPLETED
    case DROPPED

    var displayName: String {
        switch self {
        case .WISHLIST: return "Wishlist"
        case .BACKLOG: return "Backlog"
        case .PLAYING: return "Playing"
        case .PAUSED: return "Paused"
        case .COMPLETED: return "Completed"
        case .DROPPED: return "Dropped"
        }
    }

    var iconName: String {
        switch self {
        case .WISHLIST: return "heart"
        case .BACKLOG: return "tray"
        case .PLAYING: return "play.circle"
        case .PAUSED: return "pause.circle"
        case .COMPLETED: return "checkmark.circle"
        case .DROPPED: return "xmark.circle"
        }
    }

    var color: String {
        switch self {
        case .WISHLIST: return "pink"
        case .BACKLOG: return "blue"
        case .PLAYING: return "green"
        case .PAUSED: return "orange"
        case .COMPLETED: return "purple"
        case .DROPPED: return "gray"
        }
    }
}

struct LibraryItem: Codable, Identifiable {
    let id: String
    let gameId: String
    let gameTitle: String
    let gameCoverUrl: String?
    let gameDescription: String?
    let achievementCount: Int
    let platformId: String?
    let platformName: String?
    let platformSlug: String?
    let status: GameStatus
    let addedAt: String
    let updatedAt: String
}

// MARK: - Collection Models

enum GameRegion: String, Codable, CaseIterable {
    case NTSC_U
    case PAL
    case NTSC_J
    case OTHER

    var displayName: String {
        switch self {
        case .NTSC_U: return "NTSC-U"
        case .PAL: return "PAL"
        case .NTSC_J: return "NTSC-J"
        case .OTHER: return "Other"
        }
    }
}

struct CollectionItem: Decodable, Identifiable {
    let id: String
    let gameId: String
    let game: CollectionGame
    let platform: Platform?
    let hasDisc: Bool
    let hasBox: Bool
    let hasManual: Bool
    let hasExtras: Bool
    let isSealed: Bool
    let region: GameRegion
    let notes: String?
    let createdAt: String
    let updatedAt: String

    var isComplete: Bool {
        hasDisc && hasBox && hasManual
    }
}

struct CollectionGame: Decodable {
    let id: String
    let title: String
    let coverUrl: String?
}

struct CollectionStats: Codable {
    let totalItems: Int
    let sealedCount: Int
    let completeCount: Int
    let byRegion: [RegionCount]
}

struct RegionCount: Codable {
    let region: GameRegion
    let count: Int
}

// MARK: - Game Progress Models

struct GameProgress: Codable, Identifiable {
    let gameId: String
    let gameTitle: String
    let gameCoverUrl: String?
    let earnedCount: Int
    let totalCount: Int
    let earnedPoints: Int
    let totalPoints: Int
    let percentComplete: Float
    let hasTrophy: Bool
    let trophyEarnedAt: String?
    let lastActivityAt: String?
    let platformId: String?
    let platformName: String?
    let platformSlug: String?

    var id: String { gameId }
}

struct GameListResponse: Decodable {
    let games: GameConnection
}

struct GameConnection: Decodable {
    let edges: [GameEdge]
}

struct GameEdge: Decodable {
    let node: GameSummary
}

struct PlatformsResponse: Decodable {
    let platforms: [Platform]
}

struct GameDetailResponse: Decodable {
    let game: GameDetail?
}

struct UserStats: Decodable {
    let totalTrophies: Int
    let totalAchievements: Int
    let totalGamesPlayed: Int
}

struct StatsResponse: Decodable {
    let myStats: UserStats?
}

struct SimpleMutationResponse: Decodable {
    let markAchievementComplete: MutationResult?
    let unmarkAchievementComplete: MutationResult?
}

struct MutationResult: Decodable {
    let success: Bool
}

// MARK: - Leaderboard Responses

struct LeaderboardResponse: Decodable {
    let leaderboardByTrophies: [LeaderboardEntry]?
    let leaderboardByAchievements: [LeaderboardEntry]?
    let leaderboardByPoints: [LeaderboardEntry]?
    let leaderboardByGames: [LeaderboardEntry]?
}

struct FastestCompletionsResponse: Decodable {
    let fastestCompletions: [FastestCompletionEntry]
}

// MARK: - Activity Response

struct ActivityResponse: Decodable {
    let activityFeed: [ActivityEntry]
}

// MARK: - Wishlist Responses

struct WishlistResponse: Decodable {
    let myWishlist: [WishlistItem]
}

struct WishlistCheckResponse: Decodable {
    let isGameInWishlist: Bool
}

struct WishlistMutationResponse: Decodable {
    let addToWishlist: WishlistMutationResult?
    let removeFromWishlist: WishlistMutationResult?
    let toggleWishlist: WishlistToggleResult?
}

struct WishlistMutationResult: Decodable {
    let success: Bool
}

struct WishlistToggleResult: Decodable {
    let success: Bool
    let isInWishlist: Bool
}

// MARK: - Game Progress Response

struct GameProgressResponse: Decodable {
    let myGameProgress: [GameProgress]
}

// MARK: - Library Responses

struct LibraryResponse: Decodable {
    let myGamesByStatus: [LibraryItem]
}

struct GameStatusInfo: Decodable {
    let status: GameStatus
    let platformId: String?
}

struct GameStatusResponse: Decodable {
    let getGameStatus: GameStatusInfo?
}

struct SetGameStatusResponse: Decodable {
    let setGameStatus: SetGameStatusResult
}

struct SetGameStatusResult: Decodable {
    let success: Bool
    let status: GameStatus?
    let platformId: String?
}

struct ClearGameStatusResponse: Decodable {
    let clearGameStatus: ClearStatusResult
}

struct ClearStatusResult: Decodable {
    let success: Bool
}

// MARK: - Collection Responses

struct CollectionResponse: Decodable {
    let myCollection: [CollectionItem]
}

struct CollectionForGameResponse: Decodable {
    let myCollectionForGame: [CollectionItem]
}

struct CollectionStatsResponse: Decodable {
    let collectionStats: CollectionStats
}

struct AddToCollectionResponse: Decodable {
    let addToCollection: CollectionMutationResult
}

struct UpdateCollectionItemResponse: Decodable {
    let updateCollectionItem: CollectionMutationResult
}

struct RemoveFromCollectionResponse: Decodable {
    let removeFromCollection: RemoveFromCollectionResult
}

struct CollectionMutationResult: Decodable {
    let success: Bool
    let collectionItem: CollectionItem?
}

struct RemoveFromCollectionResult: Decodable {
    let success: Bool
}

// MARK: - User Profile Models

struct PublicUser: Codable, Identifiable {
    let id: String
    let email: String
    let name: String?
    let achievementCount: Int
    let trophyCount: Int
    let gamesWithAchievementsCount: Int
    let stats: UserProfileStats?
}

struct UserProfileStats: Codable {
    let totalPoints: Int
    let goldCount: Int
    let silverCount: Int
    let bronzeCount: Int
    let completionRate: Float
    let averagePointsPerGame: Float
}

struct PublicUserResponse: Decodable {
    let user: PublicUser?
}
