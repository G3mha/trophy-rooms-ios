import SwiftUI

/// Badge for displaying game type (Base Game, Fangame, ROM Hack, DLC, Expansion)
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
        case .MOD: return .pink
        case .DLC: return .green
        case .EXPANSION: return .teal
        }
    }

    var badgeIcon: String? {
        switch self {
        case .BASE_GAME: return nil
        case .FANGAME: return "heart.fill"
        case .ROM_HACK: return "wrench.and.screwdriver"
        case .MOD: return "puzzlepiece.fill"
        case .DLC: return "plus.square.fill"
        case .EXPANSION: return "rectangle.stack.fill"
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
