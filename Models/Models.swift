import Foundation

struct Platform: Identifiable, Decodable {
    let id: String
    let name: String
    let slug: String
}

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
    let achievementSets: [AchievementSet]
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
