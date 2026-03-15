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
    let addedAt: String
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
