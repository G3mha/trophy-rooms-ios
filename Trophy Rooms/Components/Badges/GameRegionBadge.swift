import SwiftUI

/// Badge for displaying game region
struct GameRegionBadge: View {
    let region: GameRegion

    var body: some View {
        TypeBadge(
            region.displayName,
            icon: "globe",
            color: region.badgeColor
        )
    }
}

// MARK: - GameRegion Badge Extension

extension GameRegion {
    var badgeColor: Color {
        switch self {
        case .NTSC_U: return .blue
        case .PAL: return .green
        case .NTSC_J: return .red
        case .OTHER: return .gray
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        ForEach(GameRegion.allCases, id: \.self) { region in
            GameRegionBadge(region: region)
        }
    }
    .padding()
}
