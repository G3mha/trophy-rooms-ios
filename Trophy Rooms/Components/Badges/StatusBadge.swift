import SwiftUI

/// Badge for displaying game status (Playing, Completed, etc.)
struct GameStatusBadge: View {
    let status: GameStatus

    var body: some View {
        TypeBadge(
            status.displayName,
            icon: status.iconName,
            color: status.badgeColor
        )
    }
}

// MARK: - GameStatus Badge Color Extension

extension GameStatus {
    var badgeColor: Color {
        switch self {
        case .BACKLOG: return Cabinet.Tint.info
        case .PLAYING: return Cabinet.Tint.positive
        case .PAUSED: return Cabinet.Tint.warm
        case .COMPLETED: return Cabinet.Tint.violet
        case .DROPPED: return Cabinet.Tint.muted
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        ForEach(GameStatus.allCases, id: \.self) { status in
            GameStatusBadge(status: status)
        }
    }
    .padding()
}
