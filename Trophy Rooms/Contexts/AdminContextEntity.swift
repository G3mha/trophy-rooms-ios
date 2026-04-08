import Foundation

/// Types of entities that can be tracked for inline admin actions
enum AdminEntityType: String, Equatable {
    case game
    case bundle
    case dlc
    case achievementSet
}

/// Represents the current entity being viewed that can have admin actions applied
struct AdminContextEntity: Identifiable, Equatable {
    let id: String
    let type: AdminEntityType
    let title: String
    let platformId: String?
    let platformName: String?
    let platformSlug: String?
    let coverUrl: String?
    let gameId: String?  // For DLC/AchievementSet - reference to parent game

    static func == (lhs: AdminContextEntity, rhs: AdminContextEntity) -> Bool {
        lhs.id == rhs.id && lhs.type == rhs.type
    }
}

// MARK: - Convenience Initializers

extension AdminContextEntity {
    /// Create from a GameDetail
    static func from(game: GameDetail) -> AdminContextEntity {
        AdminContextEntity(
            id: game.id,
            type: .game,
            title: game.title,
            platformId: game.platform?.id,
            platformName: game.platform?.name,
            platformSlug: game.platform?.slug,
            coverUrl: game.coverUrl,
            gameId: nil
        )
    }

    /// Create from a GameSummary
    static func from(game: GameSummary) -> AdminContextEntity {
        AdminContextEntity(
            id: game.id,
            type: .game,
            title: game.title,
            platformId: game.platform?.id,
            platformName: game.platform?.name,
            platformSlug: game.platform?.slug,
            coverUrl: game.coverUrl,
            gameId: nil
        )
    }
}
