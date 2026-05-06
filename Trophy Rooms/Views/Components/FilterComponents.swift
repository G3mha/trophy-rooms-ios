import SwiftUI

// MARK: - Filter Pill (with count badge)

/// A pill-shaped filter button with a count badge.
/// Used for filters that show item counts (e.g., status filters, priority filters).
struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip (simple, without count)

/// A simple chip-shaped filter button without count.
/// Used for toggle filters (e.g., Sealed, Complete) and dropdown menus (e.g., Platform, Region).
struct FilterChip: View {
    let title: String
    let isActive: Bool
    var activeColor: Color = .blue

    var body: some View {
        Text(title)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? activeColor : Color(.secondarySystemBackground))
            .foregroundColor(isActive ? .white : .primary)
            .cornerRadius(16)
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
        .background(Color(.systemBackground))
    }
}

// MARK: - Common Filter Colors

/// Standard color for the "All" filter pill when selected.
let filterAllColor = Color(.darkGray)
