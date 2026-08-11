import SwiftUI

/// Badge for displaying DLC type
struct DLCBadge: View {
    let type: DLCType

    var body: some View {
        TypeBadge(
            type.displayName,
            color: type.badgeColor
        )
    }
}

// MARK: - DLCType Badge Extension

extension DLCType {
    var badgeColor: Color {
        switch self {
        case .DLC: return Cabinet.Tint.info
        case .EXPANSION: return Cabinet.Tint.violet
        case .FREE_UPDATE: return Cabinet.Tint.positive
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        ForEach(DLCType.allCases, id: \.self) { type in
            DLCBadge(type: type)
        }
    }
    .padding()
}
