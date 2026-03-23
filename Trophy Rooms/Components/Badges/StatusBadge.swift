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
        case .BACKLOG: return .blue
        case .PLAYING: return .green
        case .PAUSED: return .orange
        case .COMPLETED: return .purple
        case .DROPPED: return .gray
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
