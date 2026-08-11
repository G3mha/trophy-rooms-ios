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
        case .NTSC_U: return Cabinet.Tint.info
        case .PAL: return Cabinet.Tint.positive
        case .NTSC_J: return Cabinet.Tint.alert
        case .OTHER: return Cabinet.Tint.muted
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
