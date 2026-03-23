import SwiftUI

// MARK: - GameStatus Color Extension

extension GameStatus {
    /// Returns the SwiftUI Color associated with this status
    var statusColor: Color {
        switch self {
        case .WISHLIST: return .pink  // Legacy
        case .BACKLOG: return .blue
        case .PLAYING: return .green
        case .PAUSED: return .orange
        case .COMPLETED: return .purple
        case .DROPPED: return .gray
        }
    }
}

// MARK: - AchievementTier Color Extension

extension AchievementTier {
    /// Returns the SwiftUI Color for this tier
    var tierColor: Color {
        switch self {
        case .BRONZE: return Color(red: 0.804, green: 0.498, blue: 0.196)
        case .SILVER: return Color(red: 0.753, green: 0.753, blue: 0.753)
        case .GOLD: return Color(red: 1.0, green: 0.843, blue: 0.0)
        }
    }

    /// Returns the text color for this tier (for contrast)
    var tierTextColor: Color {
        switch self {
        case .BRONZE: return .white
        case .SILVER: return .black
        case .GOLD: return .black
        }
    }
}

// MARK: - UserRole Color Extension

extension UserRole {
    /// Returns the SwiftUI Color for this role
    var roleColor: Color {
        switch self {
        case .USER: return .secondary
        case .TRUSTED: return .blue
        case .ADMIN: return .red
        }
    }
}

// MARK: - AchievementSetType Color Extension

extension AchievementSetType {
    /// Returns the SwiftUI Color for this set type
    var typeColor: Color {
        switch self {
        case .OFFICIAL: return .blue
        case .COMMUNITY: return .green
        case .CUSTOM: return .purple
        }
    }
}

// MARK: - AchievementSetVisibility Color Extension

extension AchievementSetVisibility {
    /// Returns the SwiftUI Color for this visibility
    var visibilityColor: Color {
        switch self {
        case .PUBLIC: return .green
        case .PRIVATE: return .red
        case .UNLISTED: return .orange
        }
    }
}
