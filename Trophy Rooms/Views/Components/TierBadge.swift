import SwiftUI

struct TierBadge: View {
    let tier: AchievementTier

    var color: Color {
        switch tier {
        case .BRONZE: return Color(red: 0.804, green: 0.498, blue: 0.196)
        case .SILVER: return Color(red: 0.753, green: 0.753, blue: 0.753)
        case .GOLD: return Color(red: 1.0, green: 0.843, blue: 0.0)
        case .PLATINUM: return Color(red: 0.898, green: 0.894, blue: 0.886)
        }
    }

    var textColor: Color {
        switch tier {
        case .BRONZE: return .white
        case .SILVER: return .black
        case .GOLD: return .black
        case .PLATINUM: return .black
        }
    }

    var body: some View {
        Text(tier.rawValue)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .foregroundColor(textColor)
            .cornerRadius(4)
    }
}
