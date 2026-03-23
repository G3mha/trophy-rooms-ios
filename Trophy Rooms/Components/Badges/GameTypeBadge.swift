import SwiftUI

/// Badge for displaying game type (Base Game, Fangame, ROM Hack)
struct GameTypeBadge: View {
    let type: GameType

    var body: some View {
        TypeBadge(
            type.shortName,
            icon: type.badgeIcon,
            color: type.badgeColor
        )
    }
}

// MARK: - GameType Badge Extension

extension GameType {
    var badgeColor: Color {
        switch self {
        case .BASE_GAME: return .blue
        case .FANGAME: return .orange
        case .ROM_HACK: return .purple
        }
    }

    var badgeIcon: String? {
        switch self {
        case .BASE_GAME: return nil
        case .FANGAME: return "heart.fill"
        case .ROM_HACK: return "wrench.and.screwdriver"
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        ForEach(GameType.allCases, id: \.self) { type in
            GameTypeBadge(type: type)
        }
    }
    .padding()
}
