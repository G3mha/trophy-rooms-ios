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

    /// Delegates to `Tag` so every type-specific badge in the app inherits
    /// the one tag treatment. The legacy `style` is kept for call-site
    /// compatibility but no longer changes the shape.
    var body: some View {
        Tag(text, icon: icon, tint: color)
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
        TypeBadge("DLC", color: Cabinet.Tint.info)
        TypeBadge("Expansion", color: Cabinet.Tint.violet)
        TypeBadge("Free", color: Cabinet.Tint.positive)
    }
    .padding()
}

#Preview("Filled Style") {
    HStack {
        TypeBadge("DLC", color: Cabinet.Tint.info, style: .filled)
        TypeBadge("Expansion", color: Cabinet.Tint.violet, style: .filled)
        TypeBadge("Free", color: Cabinet.Tint.positive, style: .filled)
    }
    .padding()
}

#Preview("With Icons") {
    HStack {
        TypeBadge("Playing", icon: "play.circle", color: Cabinet.Tint.positive)
        TypeBadge("Completed", icon: "checkmark.circle", color: Cabinet.Tint.violet)
        TypeBadge("PS5", icon: "gamecontroller", color: Cabinet.Tint.info)
    }
    .padding()
}
