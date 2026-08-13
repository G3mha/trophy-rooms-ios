import SwiftUI

/// The app's single tag treatment (see .claude/skills/trophy-cabinet-design).
///
/// Every classifying label - type, status, region, condition, priority,
/// edition - uses this so tags read as one system: capsule shape, uppercase
/// letter-spaced caption, faint tinted fill behind a hairline tinted border.
/// Semantic tints are preserved (green completes, crimson warns); only the
/// treatment is unified.
///
/// Two exceptions deliberately look different because their context differs:
/// - `PlaqueBadge` (engraved brass) is reserved for awards/achievement sets
/// - `.overlay` style adds a dark scrim so tags stay legible over cover art
struct Tag: View {
    enum Style {
        /// Default: on a card or the canvas
        case standard
        /// Floating over cover art - needs its own dark backing
        case overlay
    }

    let text: String
    let icon: String?
    let tint: Color
    let style: Style

    init(
        _ text: String,
        icon: String? = nil,
        tint: Color = Cabinet.brass,
        style: Style = .standard
    ) {
        self.text = text
        self.icon = icon
        self.tint = tint
        self.style = style
    }

    /// The tint, raised to WCAG AA against whatever the tag sits on if it does
    /// not already clear it. Ribbon crimson (3.04:1 on `Cabinet.card`) and warm
    /// gray (4.12:1) are the two that need it; the rest pass untouched.
    ///
    /// Only the glyphs use this. The capsule fill and border below keep the
    /// unmodified `tint`, so the tag still reads as the approved colour.
    private var legibleTint: Color {
        let backdrop = style == .overlay ? Cabinet.ink : Cabinet.card
        let base = style == .overlay ? tint.opacity(0.95) : tint
        return base.legible(on: backdrop)
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 8, weight: .bold))
            }
            Text(text.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.7)
                .lineLimit(1)
        }
        .foregroundStyle(legibleTint)
        .padding(.horizontal, 7)
        .padding(.vertical, 3.5)
        .background(
            Capsule().fill(
                style == .overlay
                    ? Cabinet.ink.opacity(0.78)
                    : tint.opacity(0.14)
            )
        )
        .overlay(
            Capsule().stroke(tint.opacity(style == .overlay ? 0.5 : 0.32), lineWidth: 1)
        )
        .fixedSize()
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 6) {
            Tag("Default")
            Tag("Collection", tint: .orange)
            Tag("Official", icon: "rosette")
        }
        HStack(spacing: 6) {
            Tag("NTSC-U", tint: .blue)
            Tag("Near Mint", tint: .green)
            Tag("High", tint: Cabinet.crimson)
        }
        HStack(spacing: 6) {
            Tag("Sealed", tint: Cabinet.brass, style: .overlay)
            Tag("CIB", tint: .green, style: .overlay)
        }
    }
    .padding(40)
    .background(Cabinet.canvas)
}
