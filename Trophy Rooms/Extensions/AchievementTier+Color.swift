import SwiftUI

// MARK: - AchievementTier Color Extension

extension AchievementTier {
    /// Returns the SwiftUI Color for this tier
    var tierColor: Color {
        switch self {
        case .BRONZE: return Color(red: 0.804, green: 0.498, blue: 0.196)
        case .SILVER: return Color(red: 0.753, green: 0.753, blue: 0.753)
        case .GOLD: return Color(red: 1.0, green: 0.843, blue: 0.0)
        case .PLATINUM: return Color(red: 0.898, green: 0.894, blue: 0.886)
        }
    }
}
