import SwiftUI

extension AchievementTier {
    var accentColor: Color {
        switch self {
        case .BRONZE: return Color(red: 0.804, green: 0.498, blue: 0.196)
        case .SILVER: return Color(red: 0.726, green: 0.756, blue: 0.804)
        case .GOLD: return Color(red: 1.0, green: 0.843, blue: 0.0)
        case .PLATINUM: return Color(red: 0.545, green: 0.835, blue: 1.0)
        }
    }

    var secondaryAccentColor: Color {
        switch self {
        case .BRONZE: return Color(red: 0.949, green: 0.756, blue: 0.459)
        case .SILVER: return Color(red: 0.906, green: 0.929, blue: 0.965)
        case .GOLD: return Color(red: 1.0, green: 0.949, blue: 0.584)
        case .PLATINUM: return Color(red: 0.82, green: 0.58, blue: 1.0)
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .BRONZE: return "Bronze achievement"
        case .SILVER: return "Silver achievement"
        case .GOLD: return "Gold achievement"
        case .PLATINUM: return "Platinum achievement"
        }
    }
}

struct TierBadge: View {
    let tier: AchievementTier

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [tier.secondaryAccentColor, tier.accentColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(tier == .PLATINUM ? 0.42 : 0.18), lineWidth: tier == .PLATINUM ? 1.4 : 1)
                )

            if tier == .PLATINUM {
                Image(systemName: "sparkles")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(Color.black.opacity(0.55))
            } else {
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 4, height: 4)
                    .offset(x: -3, y: -3)
            }
        }
        .frame(width: tier == .PLATINUM ? 20 : 16, height: tier == .PLATINUM ? 20 : 16)
        .shadow(
            color: tier == .PLATINUM
                ? tier.accentColor.opacity(0.55)
                : tier == .GOLD
                    ? tier.accentColor.opacity(0.25)
                    : .clear,
            radius: tier == .PLATINUM ? 7 : 4,
            y: 1
        )
        .accessibilityLabel(Text(tier.accessibilityLabel))
    }
}
