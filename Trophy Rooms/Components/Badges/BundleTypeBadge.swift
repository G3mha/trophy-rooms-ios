import SwiftUI

/// Badge for displaying bundle type
struct BundleBadge: View {
    let type: BundleType

    var body: some View {
        TypeBadge(
            type.displayName,
            color: type.badgeColor
        )
    }
}

// MARK: - BundleType Badge Extension

extension BundleType {
    var badgeColor: Color {
        switch self {
        case .BUNDLE: return .blue
        case .SEASON_PASS: return .orange
        case .COLLECTION: return .purple
        case .SUBSCRIPTION: return .green
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        ForEach(BundleType.allCases, id: \.self) { type in
            BundleBadge(type: type)
        }
    }
    .padding()
}
