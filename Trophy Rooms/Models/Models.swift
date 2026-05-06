import Foundation

// MARK: - Sort Option Protocol

protocol SortOption: CaseIterable, Identifiable, Hashable {
    var title: String { get }
    var shortTitle: String { get }
}

// MARK: - Achievement Tier

enum AchievementTier: String, Codable, CaseIterable {
    case BRONZE
    case SILVER
    case GOLD
    case PLATINUM
}

// MARK: - Platform

struct Platform: Identifiable, Decodable {
    let id: String
    let name: String
    let slug: String?
}

// MARK: - GameFamily Models

/// Canonical representation of a game across all platforms
struct GameFamily: Identifiable, Decodable, Equatable {
    let id: String
    let title: String
    let slug: String
    let description: String?
    let coverUrl: String?
    let type: GameType?
    let developer: String?
    let publisher: String?
    let genre: String?
    let esrbRating: String?
    let screenshots: [String]?
    let releaseDate: String?
    let games: [GamePlatformInstance]?
    let gameCount: Int?
    let platforms: [Platform]?
    let achievementSets: [AchievementSet]?
    let totalAchievementCount: Int?
    let totalTrophyCount: Int?
    let dlcs: [GameDLC]?
    let dlcCount: Int?
    let baseGameFamilies: [GameFamilyRef]?
    let derivedGameFamilies: [GameFamilyRef]?

    static func == (lhs: GameFamily, rhs: GameFamily) -> Bool {
        lhs.id == rhs.id
    }

    var isDerivative: Bool {
        type == .FANGAME || type == .ROM_HACK || type == .MOD || type == .DLC || type == .EXPANSION
    }

    var hasBaseGameFamilies: Bool {
        guard let baseGameFamilies = baseGameFamilies else { return false }
        return !baseGameFamilies.isEmpty
    }
}

/// Reference to a GameFamily (for self-referencing relations)
struct GameFamilyRef: Identifiable, Decodable {
    let id: String
    let title: String
    let slug: String
    let coverUrl: String?
    let type: GameType?
}

/// A platform-specific instance of a game
struct GamePlatformInstance: Identifiable, Decodable {
    let id: String
    let gameFamilyId: String
    let platform: Platform?
    let platformId: String?
    let releaseDate: String?
    let coverUrl: String?  // Platform-specific override
    let trophyCount: Int?
}

// MARK: - Game Models

struct GameSummary: Identifiable, Decodable, Equatable {
    let id: String
    let title: String
    let description: String?
    let coverUrl: String?
    let type: GameType?
    let gameFamilyId: String?
    let baseGameFamilyId: String?       // First base game family
    let baseGameFamilyIds: [String]?    // All base game family IDs
    let platform: Platform?
    let achievementSetCount: Int
    let achievementCount: Int
    let trophyCount: Int

    // Memberwise initializer for programmatic creation
    init(
        id: String,
        title: String,
        description: String? = nil,
        coverUrl: String? = nil,
        type: GameType? = nil,
        gameFamilyId: String? = nil,
        baseGameFamilyId: String? = nil,
        baseGameFamilyIds: [String]? = nil,
        platform: Platform? = nil,
        achievementSetCount: Int = 0,
        achievementCount: Int = 0,
        trophyCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.coverUrl = coverUrl
        self.type = type
        self.gameFamilyId = gameFamilyId
        self.baseGameFamilyId = baseGameFamilyId
        self.baseGameFamilyIds = baseGameFamilyIds
        self.platform = platform
        self.achievementSetCount = achievementSetCount
        self.achievementCount = achievementCount
        self.trophyCount = trophyCount
    }

    static func == (lhs: GameSummary, rhs: GameSummary) -> Bool {
        lhs.id == rhs.id
    }

    var isDerivative: Bool {
        type == .FANGAME || type == .ROM_HACK || type == .MOD || type == .DLC || type == .EXPANSION
    }

    var hasBaseGameFamilies: Bool {
        if let baseGameFamilyIds = baseGameFamilyIds, !baseGameFamilyIds.isEmpty {
            return true
        }
        return baseGameFamilyId != nil
    }
}

struct AchievementSet: Identifiable, Decodable {
    let id: String
    let title: String
    let type: String
    let visibility: String
    let gameFamilyId: String?
    let createdByUserId: String?
    let gameVersionId: String?
    let gameVersion: GameVersionRef?
    let dlcId: String?
    let dlc: DLCRef?
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

extension Achievement {
    func withCompletionState(_ isCompleted: Bool) -> Achievement {
        Achievement(
            id: id,
            title: title,
            description: description,
            iconUrl: iconUrl,
            points: points,
            tier: tier,
            isCompleted: isCompleted,
            userCount: updatedUserCount(for: isCompleted),
            achievementSetId: achievementSetId
        )
    }

    private func updatedUserCount(for isCompleted: Bool) -> Int? {
        guard let userCount else { return nil }
        return isCompleted ? userCount + 1 : max(0, userCount - 1)
    }
}

struct GameDetail: Identifiable, Decodable {
    let id: String
    let gameFamilyId: String?
    let gameFamily: GameFamilyRef?
    let title: String
    let description: String?
    let coverUrl: String?
    let type: GameType?
    let baseGameFamilies: [GameFamilyRef]?
    let derivedGameFamilies: [GameFamilyRef]?
    let derivedGameFamilyCount: Int?
    let trophyCount: Int
    let releaseDate: String?
    let developer: String?
    let publisher: String?
    let genre: String?
    let esrbRating: String?
    let screenshots: [String]?
    let platform: Platform?
    let achievementSets: [AchievementSet]
    let versions: [GameVersion]?
    let versionCount: Int?
    let defaultVersion: GameVersion?
    let dlcs: [GameDLC]?
    let dlcCount: Int?
    let bundles: [GameBundle]?

    var isDerivative: Bool {
        type == .FANGAME || type == .ROM_HACK || type == .MOD || type == .DLC || type == .EXPANSION
    }

    var hasBaseGameFamilies: Bool {
        guard let baseGameFamilies = baseGameFamilies else { return false }
        return !baseGameFamilies.isEmpty
    }
}

extension AchievementSet {
    func replacingAchievement(_ updatedAchievement: Achievement) -> AchievementSet {
        AchievementSet(
            id: id,
            title: title,
            type: type,
            visibility: visibility,
            gameFamilyId: gameFamilyId,
            createdByUserId: createdByUserId,
            gameVersionId: gameVersionId,
            gameVersion: gameVersion,
            dlcId: dlcId,
            dlc: dlc,
            achievements: achievements.map { achievement in
                achievement.id == updatedAchievement.id ? updatedAchievement : achievement
            }
        )
    }
}

extension GameDetail {
    func replacingAchievement(_ updatedAchievement: Achievement) -> GameDetail {
        GameDetail(
            id: id,
            gameFamilyId: gameFamilyId,
            gameFamily: gameFamily,
            title: title,
            description: description,
            coverUrl: coverUrl,
            type: type,
            baseGameFamilies: baseGameFamilies,
            derivedGameFamilies: derivedGameFamilies,
            derivedGameFamilyCount: derivedGameFamilyCount,
            trophyCount: trophyCount,
            releaseDate: releaseDate,
            developer: developer,
            publisher: publisher,
            genre: genre,
            esrbRating: esrbRating,
            screenshots: screenshots,
            platform: platform,
            achievementSets: achievementSets.map { set in
                set.id == updatedAchievement.achievementSetId ? set.replacingAchievement(updatedAchievement) : set
            },
            versions: versions,
            versionCount: versionCount,
            defaultVersion: defaultVersion,
            dlcs: dlcs,
            dlcCount: dlcCount,
            bundles: bundles
        )
    }
}

// Reference to base game for derivatives (deprecated, use GameFamilyRef)
struct BaseGameRef: Identifiable, Decodable {
    let id: String
    let title: String
    let coverUrl: String?
    let platform: Platform?
}

// Derivative game (fangame/ROM hack) reference (deprecated, use GameFamilyRef)
struct DerivativeGame: Identifiable, Decodable {
    let id: String
    let title: String
    let coverUrl: String?
    let type: GameType
    let platform: Platform?
}

// MARK: - User-Facing DLC

struct GameDLC: Identifiable, Decodable {
    let id: String
    let name: String
    let slug: String
    let type: DLCType
    let description: String?
    let coverUrl: String?
    let effectiveCoverUrl: String?
    let releaseDate: String?
    let price: Double?
    let isOwned: Bool?
    let achievementSetCount: Int?
}

// MARK: - User-Facing Bundle

struct GameBundle: Identifiable, Decodable {
    let id: String
    let name: String
    let slug: String
    let type: BundleType
    let description: String?
    let coverUrl: String?
    let gameFamilyCount: Int
    let dlcCount: Int
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
    let gameFamilyId: String?
    let gameTitle: String
    let platformName: String?
    let platformSlug: String?
    let earnedAt: String
}

// MARK: - Buylist Models

enum BuylistSortOption: String, CaseIterable, Identifiable, SortOption {
    case priorityDesc = "PRIORITY_DESC"
    case priorityAsc = "PRIORITY_ASC"
    case dateAddedDesc = "ADDED_AT_DESC"
    case dateAddedAsc = "ADDED_AT_ASC"
    case priceDesc = "PRICE_DESC"
    case priceAsc = "PRICE_ASC"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .priorityDesc: return "Priority (High first)"
        case .priorityAsc: return "Priority (Low first)"
        case .dateAddedDesc: return "Date Added (Newest)"
        case .dateAddedAsc: return "Date Added (Oldest)"
        case .priceDesc: return "Price (High to Low)"
        case .priceAsc: return "Price (Low to High)"
        }
    }

    var shortTitle: String {
        switch self {
        case .priorityDesc: return "Priority"
        case .priorityAsc: return "Priority"
        case .dateAddedDesc: return "Newest"
        case .dateAddedAsc: return "Oldest"
        case .priceDesc: return "Price"
        case .priceAsc: return "Price"
        }
    }
}

// MARK: - Library Sort Option

enum LibrarySortOption: String, CaseIterable, Identifiable, SortOption {
    case titleAsc = "TITLE_ASC"
    case titleDesc = "TITLE_DESC"
    case statusAsc = "STATUS_ASC"
    case statusDesc = "STATUS_DESC"
    case dateAddedDesc = "ADDED_AT_DESC"
    case dateAddedAsc = "ADDED_AT_ASC"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .titleAsc: return "Title (A-Z)"
        case .titleDesc: return "Title (Z-A)"
        case .statusAsc: return "Status (Backlog first)"
        case .statusDesc: return "Status (Completed first)"
        case .dateAddedDesc: return "Date Added (Newest)"
        case .dateAddedAsc: return "Date Added (Oldest)"
        }
    }

    var shortTitle: String {
        switch self {
        case .titleAsc, .titleDesc: return "Title"
        case .statusAsc, .statusDesc: return "Status"
        case .dateAddedDesc: return "Newest"
        case .dateAddedAsc: return "Oldest"
        }
    }
}

// MARK: - Collection Sort Option

enum CollectionSortOption: String, CaseIterable, Identifiable, SortOption {
    case titleAsc = "TITLE_ASC"
    case titleDesc = "TITLE_DESC"
    case dateAddedDesc = "ADDED_AT_DESC"
    case dateAddedAsc = "ADDED_AT_ASC"
    case regionAsc = "REGION_ASC"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .titleAsc: return "Title (A-Z)"
        case .titleDesc: return "Title (Z-A)"
        case .dateAddedDesc: return "Date Added (Newest)"
        case .dateAddedAsc: return "Date Added (Oldest)"
        case .regionAsc: return "Region"
        }
    }

    var shortTitle: String {
        switch self {
        case .titleAsc, .titleDesc: return "Title"
        case .dateAddedDesc: return "Newest"
        case .dateAddedAsc: return "Oldest"
        case .regionAsc: return "Region"
        }
    }
}

struct BuylistPlatform: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let slug: String?

    static func == (lhs: BuylistPlatform, rhs: BuylistPlatform) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum BuylistPriority: String, Codable, CaseIterable {
    case HIGH
    case MEDIUM
    case LOW

    var displayName: String {
        switch self {
        case .HIGH: return "High"
        case .MEDIUM: return "Medium"
        case .LOW: return "Low"
        }
    }

    var iconName: String {
        switch self {
        case .HIGH: return "arrow.up"
        case .MEDIUM: return "arrow.right"
        case .LOW: return "arrow.down"
        }
    }

    var color: String {
        switch self {
        case .HIGH: return "red"
        case .MEDIUM: return "orange"
        case .LOW: return "green"
        }
    }
}

enum BuylistItemType: String, Codable, CaseIterable {
    case GAME
    case DLC
    case BUNDLE

    var displayName: String {
        switch self {
        case .GAME: return "Game"
        case .DLC: return "DLC"
        case .BUNDLE: return "Bundle"
        }
    }

    var iconName: String {
        switch self {
        case .GAME: return "gamecontroller"
        case .DLC: return "plus.rectangle.on.rectangle"
        case .BUNDLE: return "shippingbox"
        }
    }
}

struct BuylistItem: Codable, Identifiable {
    let id: String
    let gameFamilyId: String?
    let gameId: String?
    let gameVersionId: String?
    let dlcId: String?
    let bundleId: String?
    let priority: BuylistPriority
    let notes: String?
    let estimatedPrice: Double?
    let itemType: BuylistItemType
    let displayTitle: String
    let displayCoverUrl: String?
    let displayPlatform: BuylistPlatform?
    let addedAt: String
    let updatedAt: String
}

struct BuylistStats: Codable {
    let totalItems: Int
    let totalEstimatedCost: Double
    let highPriorityCount: Int
    let mediumPriorityCount: Int
    let lowPriorityCount: Int
    let gameCount: Int
    let dlcCount: Int
    let bundleCount: Int
}

// MARK: - Buylist Responses

struct BuylistResponse: Decodable {
    let myBuylist: [BuylistItem]
}

struct UserBuylistResponse: Decodable {
    let userBuylist: [BuylistItem]
}

struct BuylistStatsResponse: Decodable {
    let buylistStats: BuylistStats
}

struct IsInBuylistResponse: Decodable {
    let isInBuylist: Bool
}

struct AddToBuylistResponse: Decodable {
    let addToBuylist: BuylistMutationResult
}

struct RemoveFromBuylistResponse: Decodable {
    let removeFromBuylist: BuylistMutationResult
}

struct UpdateBuylistItemResponse: Decodable {
    let updateBuylistItem: BuylistMutationResult
}

struct MarkAsPurchasedResponse: Decodable {
    let markAsPurchased: BuylistMutationResult
}

struct BuylistMutationResult: Decodable {
    let success: Bool
    let buylistItem: BuylistItemRef?
}

struct BuylistItemRef: Decodable {
    let id: String
}

// MARK: - Library Models

enum GameStatus: String, Codable, CaseIterable {
    case BACKLOG
    case PLAYING
    case PAUSED
    case COMPLETED
    case DROPPED

    var displayName: String {
        switch self {
        case .BACKLOG: return "Backlog"
        case .PLAYING: return "Playing"
        case .PAUSED: return "Paused"
        case .COMPLETED: return "Completed"
        case .DROPPED: return "Dropped"
        }
    }

    var iconName: String {
        switch self {
        case .BACKLOG: return "tray"
        case .PLAYING: return "play.circle"
        case .PAUSED: return "pause.circle"
        case .COMPLETED: return "checkmark.circle"
        case .DROPPED: return "xmark.circle"
        }
    }

    var color: String {
        switch self {
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
    let gameVersionId: String?
    let gameVersionName: String?
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
    let gameVersion: GameVersionRef?
    let gameVersionId: String?
    let isDigital: Bool?
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
        // Digital copies are considered complete by default
        if isDigital == true { return true }
        return hasDisc && hasBox && hasManual
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
    let gameFamilyId: String
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

    var id: String { gameFamilyId }
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

// MARK: - Paginated Games Response

struct GamesPageResponse: Decodable {
    let gamesPage: GamesPage
}

struct GamesPage: Decodable {
    let items: [GameSummary]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
}

// MARK: - Games By Title Response

struct GamesByTitleResponse: Decodable {
    let gamesByTitle: [GameSummary]
}

// MARK: - Game Group (for consolidated display - maps to GameFamily concept)

struct GameGroup: Identifiable {
    let gameFamilyId: String?
    let title: String
    let slug: String
    let games: [GameSummary]
    let platforms: [Platform]
    let coverUrl: String?
    let totalAchievementCount: Int
    let totalTrophyCount: Int

    var id: String { gameFamilyId ?? slug }

    var isSingleGame: Bool { games.count == 1 }
}

struct PlatformsResponse: Decodable {
    let platforms: [Platform]
}

struct GameDetailResponse: Decodable {
    let game: GameDetail?
}

// MARK: - GameFamily Responses

struct GameFamilyResponse: Decodable {
    let gameFamily: GameFamily?
}

struct GameFamilyBySlugResponse: Decodable {
    let gameFamilyBySlug: GameFamily?
}

struct GameFamiliesPageResponse: Decodable {
    let gameFamiliesPage: GameFamiliesPage
}

struct GameFamiliesPage: Decodable {
    let items: [GameFamily]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
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
    let gameVersionId: String?
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
    let gameVersionId: String?
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
    let collectionItem: CollectionItemRef?
}

struct CollectionItemRef: Decodable {
    let id: String
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
    let platinumCount: Int
    let goldCount: Int
    let silverCount: Int
    let bronzeCount: Int
    let completionRate: Float
    let averagePointsPerGame: Float
}

struct PublicUserResponse: Decodable {
    let user: PublicUser?
}

// MARK: - Admin Models

enum UserRole: String, Codable, CaseIterable {
    case USER
    case TRUSTED
    case ADMIN

    var displayName: String {
        switch self {
        case .USER: return "User"
        case .TRUSTED: return "Trusted"
        case .ADMIN: return "Admin"
        }
    }
}

struct CurrentUser: Decodable {
    let id: String
    let role: UserRole
}

struct CurrentUserResponse: Decodable {
    let me: CurrentUser?
}

struct AdminUser: Identifiable, Decodable {
    let id: String
    let email: String
    let name: String?
    let role: UserRole
}

struct AdminUsersResponse: Decodable {
    let users: AdminUsersConnection
}

struct AdminUsersConnection: Decodable {
    let edges: [AdminUserEdge]
}

struct AdminUserEdge: Decodable {
    let node: AdminUser
}

// Admin Platform (same as Platform but explicit for admin context)
struct AdminPlatform: Identifiable, Decodable {
    let id: String
    let name: String
    let slug: String
    let description: String?
    let consolePictureUrl: String?
    let promotionalPictures: [String]?
    let releases: [PlatformRelease]?
}

struct PlatformRelease: Identifiable, Decodable {
    let id: String
    let region: String
    let releaseDate: String
}

struct AdminPlatformsResponse: Decodable {
    let platforms: [AdminPlatform]
}

// Platform Release Mutation Responses
struct CreatePlatformReleaseResponse: Decodable {
    let createPlatformRelease: PlatformReleaseMutationResult
}

struct UpdatePlatformReleaseResponse: Decodable {
    let updatePlatformRelease: PlatformReleaseMutationResult
}

struct DeletePlatformReleaseResponse: Decodable {
    let deletePlatformRelease: PlatformReleaseMutationResult
}

struct PlatformReleaseMutationResult: Decodable {
    let success: Bool
    let release: PlatformReleaseRef?
}

struct PlatformReleaseRef: Decodable {
    let id: String
}

// MARK: - DLC Models

enum DLCType: String, Codable, CaseIterable {
    case DLC
    case EXPANSION
    case FREE_UPDATE

    var displayName: String {
        switch self {
        case .DLC: return "DLC"
        case .EXPANSION: return "Expansion"
        case .FREE_UPDATE: return "Free Update"
        }
    }
}

struct DLC: Identifiable, Decodable {
    let id: String
    let name: String
    let slug: String
    let type: DLCType
    let description: String?
    let coverUrl: String?
    let effectiveCoverUrl: String?
    let releaseDate: String?
    let price: Double?
    let gameFamilyId: String
    let gameFamily: GameFamilyRef?
    let platforms: [Platform]?
    let achievementSetCount: Int?
}

struct DLCGame: Decodable {
    let id: String
    let title: String
}

struct DLCRef: Identifiable, Decodable {
    let id: String
    let name: String
    let slug: String
    let type: DLCType
}

struct DLCsResponse: Decodable {
    let dlcs: [DLC]
}

struct DLCResponse: Decodable {
    let dlc: DLC?
}

// MARK: - DLC Detail (for DLCDetailView)

struct DLCDetail: Identifiable, Decodable {
    let id: String
    let name: String
    let slug: String
    let type: DLCType
    let description: String?
    let coverUrl: String?
    let effectiveCoverUrl: String?
    let releaseDate: String?
    let price: Double?
    let isOwned: Bool?
    let gameFamily: GameFamilyRef?
    let platforms: [Platform]?
    let achievementSets: [AchievementSetSummary]?
    let bundles: [DLCBundleRef]?
}

struct AchievementSetSummary: Identifiable, Decodable {
    let id: String
    let title: String
    let achievementCount: Int
}

struct DLCBundleRef: Identifiable, Decodable {
    let id: String
    let name: String
    let type: BundleType
    let coverUrl: String?
}

struct DLCDetailResponse: Decodable {
    let dlc: DLCDetail?
}

struct CreateDLCResponse: Decodable {
    let createDLC: DLCMutationResult
}

struct UpdateDLCResponse: Decodable {
    let updateDLC: DLCMutationResult
}

struct DeleteDLCResponse: Decodable {
    let deleteDLC: DeleteDLCResult
}

struct BulkDeleteDLCsResponse: Decodable {
    let bulkDeleteDLCs: BulkDeleteResult
}

struct DLCMutationResult: Decodable {
    let success: Bool
    let dlc: DLC?
}

struct DeleteDLCResult: Decodable {
    let success: Bool
    let deletedId: String?
}

// MARK: - Bundle Models

enum BundleType: String, Codable, CaseIterable {
    case BUNDLE
    case SEASON_PASS
    case COLLECTION
    case SUBSCRIPTION

    var displayName: String {
        switch self {
        case .BUNDLE: return "Bundle"
        case .SEASON_PASS: return "Season Pass"
        case .COLLECTION: return "Collection"
        case .SUBSCRIPTION: return "Subscription"
        }
    }
}

// MARK: - Game Type (Fangames/ROM Hacks/Mods)

enum GameType: String, Codable, CaseIterable {
    case BASE_GAME
    case FANGAME
    case ROM_HACK
    case MOD
    case DLC
    case EXPANSION

    var displayName: String {
        switch self {
        case .BASE_GAME: return "Base Game"
        case .FANGAME: return "Fangame"
        case .ROM_HACK: return "ROM Hack"
        case .MOD: return "Mod"
        case .DLC: return "DLC"
        case .EXPANSION: return "Expansion"
        }
    }

    var shortName: String {
        switch self {
        case .BASE_GAME: return "Base"
        case .FANGAME: return "Fangame"
        case .ROM_HACK: return "ROM Hack"
        case .MOD: return "Mod"
        case .DLC: return "DLC"
        case .EXPANSION: return "Expansion"
        }
    }
}

struct AppBundle: Identifiable, Decodable {
    let id: String
    let name: String
    let slug: String
    let type: BundleType
    let description: String?
    let coverUrl: String?
    let releaseDate: String?
    let price: Double?
    let platform: Platform?
    let platformId: String?
    let gameFamilyCount: Int
    let dlcCount: Int
    let gameFamilies: [BundleGameFamily]?
    let dlcs: [BundleDLC]?
    let isOwned: Bool?
    let ownedPlatforms: [Platform]?
}

struct BundleGameFamily: Identifiable, Decodable {
    let id: String
    let title: String
    let coverUrl: String?
}

struct BundleDLC: Identifiable, Decodable {
    let id: String
    let name: String
    let slug: String?
    let type: DLCType?
    let coverUrl: String?
    let gameFamily: BundleGameFamily?
}

struct BundlesResponse: Decodable {
    let bundles: [AppBundle]
}

struct BundleResponse: Decodable {
    let bundle: AppBundle?
}

struct CreateBundleResponse: Decodable {
    let createBundle: BundleMutationResult
}

struct UpdateBundleResponse: Decodable {
    let updateBundle: BundleMutationResult
}

struct DeleteBundleResponse: Decodable {
    let deleteBundle: DeleteBundleResult
}

struct BulkDeleteBundlesResponse: Decodable {
    let bulkDeleteBundles: BulkDeleteResult
}

struct BundleMutationResult: Decodable {
    let success: Bool
    let bundle: AppBundle?
}

struct DeleteBundleResult: Decodable {
    let success: Bool
    let deletedId: String?
}

struct AllDLCsResponse: Decodable {
    let allDlcs: [DLCPickerItem]
}

// Simplified type for DLC picker
struct DLCPickerItem: Identifiable, Decodable {
    let id: String
    let name: String
    let type: DLCType
    let coverUrl: String?
    let gameFamily: BundleGameFamily?
}

struct AddGameFamilyToBundleResponse: Decodable {
    let addGameFamilyToBundle: SimpleMutationResult
}

struct RemoveGameFamilyFromBundleResponse: Decodable {
    let removeGameFamilyFromBundle: SimpleMutationResult
}

struct AddDLCToBundleResponse: Decodable {
    let addDLCToBundle: SimpleMutationResult
}

struct RemoveDLCFromBundleResponse: Decodable {
    let removeDLCFromBundle: SimpleMutationResult
}

struct SimpleMutationResult: Decodable {
    let success: Bool
}

// MARK: - Game Version Models

struct GameVersion: Identifiable, Decodable {
    let id: String
    let name: String
    let slug: String?
    let description: String?
    let coverUrl: String?
    let effectiveCoverUrl: String?
    let releaseDate: String?
    let dlcs: [DLCRef]?
    let dlcCount: Int?
    let isDefault: Bool
    let digitalOnly: Bool?
    let games: [GameVersionGame]?
    let gameIds: [String]?
    let achievementSetCount: Int?
}

struct GameVersionGame: Decodable {
    let id: String
    let title: String
    let platform: Platform?
}

struct GameVersionsResponse: Decodable {
    let gameVersions: [GameVersion]
}

struct GameVersionResponse: Decodable {
    let gameVersion: GameVersion?
}

struct CreateGameVersionResponse: Decodable {
    let createGameVersion: GameVersionMutationResult
}

struct UpdateGameVersionResponse: Decodable {
    let updateGameVersion: GameVersionMutationResult
}

struct DeleteGameVersionResponse: Decodable {
    let deleteGameVersion: DeleteGameVersionResult
}

struct SetDefaultVersionResponse: Decodable {
    let setDefaultVersion: GameVersionMutationResult
}

struct BulkDeleteGameVersionsResponse: Decodable {
    let bulkDeleteGameVersions: BulkDeleteResult
}

struct GameVersionMutationResult: Decodable {
    let success: Bool
    let gameVersion: GameVersion?
}

struct DeleteGameVersionResult: Decodable {
    let success: Bool
    let deletedId: String?
}

// Admin Game
struct AdminGame: Identifiable, Decodable {
    let id: String
    let gameFamilyId: String?
    let title: String
    let description: String?
    let coverUrl: String?
    let type: GameType?
    let baseGameFamilyId: String?           // First base game family
    let baseGameFamilyIds: [String]?        // All base game family IDs
    let baseGameFamilies: [GameFamilyRef]?  // Full base game family references
    let platform: Platform?
    let achievementSetCount: Int
}

// Pagination
struct PageInfo: Decodable {
    let hasNextPage: Bool
    let hasPreviousPage: Bool?
    let startCursor: String?
    let endCursor: String?
}

struct AdminGamesResponse: Decodable {
    let games: AdminGamesConnection
}

struct AdminGamesConnection: Decodable {
    let edges: [AdminGameEdge]
    let pageInfo: PageInfo?
    let totalCount: Int?
}

struct AdminGameEdge: Decodable {
    let node: AdminGame
}

// Admin games with offset pagination
struct AdminGamesPageResponse: Decodable {
    let adminGames: AdminGamesPage
}

struct AdminGamesPage: Decodable {
    let items: [AdminGameItem]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let totalPages: Int
}

struct AdminGameResponse: Decodable {
    let adminGame: AdminGameItem?
}

// Response type for fetching a single game for editing
struct GameForEditResponse: Decodable {
    let game: GameForEdit?
}

struct GameForEdit: Decodable {
    let id: String
    let gameFamilyId: String?
    let title: String
    let description: String?
    let coverUrl: String?
    let type: GameType?
    let baseGameFamilyId: String?           // First base game family
    let baseGameFamilyIds: [String]?        // All base game family IDs
    let baseGameFamilies: [GameFamilyRef]?  // Full base game family references
    let platform: Platform?
}

struct AdminGameItem: Identifiable, Decodable {
    let id: String
    let gameFamilyId: String?
    let title: String
    let description: String?
    let coverUrl: String?
    let type: GameType?
    let baseGameFamilyId: String?       // First base game family
    let baseGameFamilyIds: [String]?    // All base game family IDs
    let baseGameFamilies: [GameFamilyRef]? // Full base game family data for display
    let platformId: String?
    let platformName: String?
    let platformSlug: String?
    let achievementSetCount: Int

    var isDerivative: Bool {
        type == .FANGAME || type == .ROM_HACK || type == .MOD || type == .DLC || type == .EXPANSION
    }

    var hasBaseGameFamilies: Bool {
        if let baseGameFamilyIds = baseGameFamilyIds, !baseGameFamilyIds.isEmpty {
            return true
        }
        return baseGameFamilyId != nil
    }

    // Memberwise initializer for creating instances programmatically
    init(
        id: String,
        gameFamilyId: String?,
        title: String,
        description: String?,
        coverUrl: String?,
        type: GameType?,
        baseGameFamilyId: String?,
        baseGameFamilyIds: [String]?,
        baseGameFamilies: [GameFamilyRef]? = nil,
        platformId: String?,
        platformName: String?,
        platformSlug: String?,
        achievementSetCount: Int
    ) {
        self.id = id
        self.gameFamilyId = gameFamilyId
        self.title = title
        self.description = description
        self.coverUrl = coverUrl
        self.type = type
        self.baseGameFamilyId = baseGameFamilyId
        self.baseGameFamilyIds = baseGameFamilyIds
        self.baseGameFamilies = baseGameFamilies
        self.platformId = platformId
        self.platformName = platformName
        self.platformSlug = platformSlug
        self.achievementSetCount = achievementSetCount
    }
}

// Admin Achievement Set
enum AchievementSetType: String, Codable, CaseIterable {
    case OFFICIAL
    case COMMUNITY
    case CUSTOM

    var displayName: String {
        switch self {
        case .OFFICIAL: return "Official"
        case .COMMUNITY: return "Community"
        case .CUSTOM: return "Custom"
        }
    }
}

enum AchievementSetVisibility: String, Codable, CaseIterable {
    case PUBLIC
    case PRIVATE
    case UNLISTED

    var displayName: String {
        switch self {
        case .PUBLIC: return "Public"
        case .PRIVATE: return "Private"
        case .UNLISTED: return "Unlisted"
        }
    }
}

struct AdminAchievementSet: Identifiable, Decodable {
    let id: String
    let title: String
    let type: String
    let visibility: String
    let gameFamilyId: String?
    let gameFamily: AdminSetGameFamily?
    let gameVersionId: String?
    let gameVersion: GameVersionRef?
    let dlcId: String?
    let dlc: DLCRef?
    let achievementCount: Int?

    var typeEnum: AchievementSetType {
        AchievementSetType(rawValue: type) ?? .OFFICIAL
    }

    var visibilityEnum: AchievementSetVisibility {
        AchievementSetVisibility(rawValue: visibility) ?? .PUBLIC
    }
}

struct GameVersionRef: Decodable {
    let id: String
    let name: String
}

struct AdminSetGame: Decodable {
    let id: String
    let title: String
}

struct AdminSetGameFamily: Decodable {
    let id: String
    let title: String
    let slug: String?
}

struct AdminAchievementSetsResponse: Decodable {
    let achievementSets: [AdminAchievementSet]
}

// Admin Achievement
struct AdminAchievement: Identifiable, Decodable {
    let id: String
    let title: String
    let description: String?
    let iconUrl: String?
    let points: Int
    let tier: AchievementTier?
    let achievementSetId: String
}

struct AdminAchievementsResponse: Decodable {
    let achievementSet: AdminAchievementSetWithAchievements?
}

struct AdminAchievementSetWithAchievements: Decodable {
    let id: String
    let title: String
    let achievements: [AdminAchievement]
}

// MARK: - User-Facing Bundle List

struct BundleListItem: Identifiable, Decodable {
    let id: String
    let name: String
    let slug: String
    let type: BundleType
    let description: String?
    let coverUrl: String?
    let platform: Platform?
    let platformId: String?
    let gameFamilyCount: Int
    let dlcCount: Int
    let gameFamilies: [BundleGameFamily]?
}

struct BundlesListResponse: Decodable {
    let bundles: [BundleListItem]
}

// Note: BundleDetail reuses Bundle from admin models with isOwned field

// MARK: - Bundle Ownership Responses

struct BundleOwnershipMutationResponse: Decodable {
    let addBundleToOwned: BundleOwnershipResult?
    let removeBundleFromOwned: BundleOwnershipResult?
}

struct BundleOwnershipResult: Decodable {
    let success: Bool
}

// MARK: - DLC Ownership Responses

struct DLCOwnershipMutationResponse: Decodable {
    let addDLCToOwned: DLCOwnershipResult?
    let removeDLCFromOwned: DLCOwnershipResult?
}

struct DLCOwnershipResult: Decodable {
    let success: Bool
}

// MARK: - Admin Mutation Responses

struct CreatePlatformResponse: Decodable {
    let createPlatform: CreatePlatformResult
}

struct CreatePlatformResult: Decodable {
    let success: Bool
    let platform: AdminPlatform?
}

struct UpdatePlatformResponse: Decodable {
    let updatePlatform: UpdatePlatformResult
}

struct UpdatePlatformResult: Decodable {
    let success: Bool
    let platform: AdminPlatform?
}

struct DeletePlatformResponse: Decodable {
    let deletePlatform: DeleteResult
}

struct DeleteResult: Decodable {
    let success: Bool
}

struct CreateGameResponse: Decodable {
    let createGame: CreateGameResult
}

struct CreateGameResult: Decodable {
    let success: Bool
    let error: MutationError?
    let game: GameIdRef?
}

struct CreateGameFamilyResponse: Decodable {
    let createGameFamily: CreateGameFamilyResult
}

struct CreateGameFamilyResult: Decodable {
    let success: Bool
    let gameFamilyId: String?
    let error: MutationError?
}

struct ImportGameFamilyFromIGDBUrlResponse: Decodable {
    let importGameFamilyFromIGDBUrl: CreateGameFamilyResult
}

struct AddPlatformToGameFamilyResponse: Decodable {
    let addPlatformToGameFamily: AddPlatformToGameFamilyResult
}

struct AddPlatformToGameFamilyResult: Decodable {
    let success: Bool
    let error: MutationError?
    let game: GameIdRef?
}

struct UpdateGameResponse: Decodable {
    let updateGame: UpdateGameResult
}

struct UpdateGameResult: Decodable {
    let success: Bool
    let error: MutationError?
    let game: GameIdRef?
}

// Simple ref for mutation responses that only return id
struct GameIdRef: Decodable {
    let id: String
}

struct MutationError: Decodable {
    let code: String
    let message: String
    let field: String?
}

struct DeleteGameResponse: Decodable {
    let deleteGame: DeleteResult
}

struct CreateAchievementSetResponse: Decodable {
    let createAchievementSet: CreateSetResult
}

struct CreateSetResult: Decodable {
    let success: Bool
    let achievementSet: AdminAchievementSet?
}

struct UpdateAchievementSetResponse: Decodable {
    let updateAchievementSet: UpdateSetResult
}

struct UpdateSetResult: Decodable {
    let success: Bool
    let achievementSet: AdminAchievementSet?
}

struct DeleteAchievementSetResponse: Decodable {
    let deleteAchievementSet: DeleteResult
}

struct CreateAchievementResponse: Decodable {
    let createAchievement: CreateAchievementResult
}

struct CreateAchievementResult: Decodable {
    let success: Bool
    let achievement: AdminAchievement?
}

struct UpdateAchievementResponse: Decodable {
    let updateAchievement: UpdateAchievementResult
}

struct UpdateAchievementResult: Decodable {
    let success: Bool
    let achievement: AdminAchievement?
}

struct DeleteAchievementResponse: Decodable {
    let deleteAchievement: DeleteResult
}

struct BulkCreateAchievementsResponse: Decodable {
    let bulkCreateAchievements: BulkCreateResult
}

struct BulkCreateResult: Decodable {
    let success: Bool
    let createdCount: Int
    let skippedCount: Int
}

struct SetUserRoleResponse: Decodable {
    let setUserRole: SetUserRoleResult
}

struct SetUserRoleResult: Decodable {
    let success: Bool
    let user: AdminUser?
}

// Bulk delete responses
struct BulkDeleteResult: Decodable {
    let success: Bool
    let deletedCount: Int
}

struct BulkDeletePlatformsResponse: Decodable {
    let bulkDeletePlatforms: BulkDeleteResult
}

struct BulkDeleteGamesResponse: Decodable {
    let bulkDeleteGames: BulkDeleteResult
}

struct BulkDeleteAchievementSetsResponse: Decodable {
    let bulkDeleteAchievementSets: BulkDeleteResult
}

struct BulkDeleteAchievementsResponse: Decodable {
    let bulkDeleteAchievements: BulkDeleteResult
}

struct CloneGameResponse: Decodable {
    let cloneGameToPlatform: CloneGameResult
}

struct CloneGameResult: Decodable {
    let success: Bool
    let game: ClonedGameRef?
    let error: MutationError?
}

struct ClonedGameRef: Decodable {
    let id: String
}

// MARK: - Global Search

enum SearchResultType: String, Codable {
    case GAME
    case BUNDLE
    case DLC
}

struct GlobalSearchItem: Identifiable, Decodable {
    let id: String
    let type: SearchResultType
    let title: String
    let coverUrl: String?
    let subtitle: String?
}

struct GlobalSearchResults: Decodable {
    let items: [GlobalSearchItem]
    let gameCount: Int
    let bundleCount: Int
    let dlcCount: Int
    let totalCount: Int

    static let empty = GlobalSearchResults(
        items: [],
        gameCount: 0,
        bundleCount: 0,
        dlcCount: 0,
        totalCount: 0
    )
}

struct GlobalSearchResponse: Decodable {
    let globalSearch: GlobalSearchResults?
}
