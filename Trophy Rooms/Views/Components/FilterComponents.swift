import SwiftUI

// MARK: - Filter Pill (with count badge)

/// A capsule filter button with a count badge.
/// Used for filters that show item counts (e.g., status filters, priority filters).
struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                Text("\(count)")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        isSelected
                            ? AnyShapeStyle(.white.opacity(0.25))
                            : AnyShapeStyle(.fill.tertiary),
                        in: .capsule
                    )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? Color.white : .primary)
            .background(
                isSelected ? AnyShapeStyle(color) : AnyShapeStyle(.fill.secondary),
                in: .capsule
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip (simple, without count)

/// A simple capsule filter label without count.
/// Used for toggle filters (e.g., Sealed, Complete) and dropdown menus (e.g., Platform, Region).
struct FilterChip: View {
    let title: String
    let isActive: Bool
    var activeColor: Color = .accentColor

    var body: some View {
        Text(title)
            .font(.subheadline.weight(isActive ? .semibold : .regular))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .foregroundStyle(isActive ? Color.white : .primary)
            .background(
                isActive ? AnyShapeStyle(activeColor) : AnyShapeStyle(.fill.secondary),
                in: .capsule
            )
    }
}

// MARK: - Filter Bar Container

/// A horizontally scrolling container for filter pills/chips.
struct FilterBarContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                content
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Common Filter Colors

/// Standard color for the "All" filter pill when selected.
let filterAllColor = Color.gray
