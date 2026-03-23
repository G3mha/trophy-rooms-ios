import SwiftUI

/// A generic badge component with consistent styling
/// Used as the base for all type-specific badges
struct TypeBadge: View {
    let text: String
    let icon: String?
    let color: Color
    let style: BadgeStyle

    enum BadgeStyle {
        case filled
        case tinted
    }

    init(
        _ text: String,
        icon: String? = nil,
        color: Color,
        style: BadgeStyle = .tinted
    ) {
        self.text = text
        self.icon = icon
        self.color = color
        self.style = style
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(8)
    }

    private var backgroundColor: Color {
        switch style {
        case .filled:
            return color
        case .tinted:
            return color.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .filled:
            return .white
        case .tinted:
            return color
        }
    }
}

// MARK: - Protocol for Badge Types

protocol BadgeType {
    var displayName: String { get }
    var badgeColor: Color { get }
    var badgeIcon: String? { get }
}

extension BadgeType {
    var badgeIcon: String? { nil }
}

#Preview("Tinted Style") {
    HStack {
        TypeBadge("DLC", color: .blue)
        TypeBadge("Expansion", color: .purple)
        TypeBadge("Free", color: .green)
    }
    .padding()
}

#Preview("Filled Style") {
    HStack {
        TypeBadge("DLC", color: .blue, style: .filled)
        TypeBadge("Expansion", color: .purple, style: .filled)
        TypeBadge("Free", color: .green, style: .filled)
    }
    .padding()
}

#Preview("With Icons") {
    HStack {
        TypeBadge("Playing", icon: "play.circle", color: .green)
        TypeBadge("Completed", icon: "checkmark.circle", color: .purple)
        TypeBadge("PS5", icon: "gamecontroller", color: .blue)
    }
    .padding()
}
