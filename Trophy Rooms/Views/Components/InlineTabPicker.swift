import SwiftUI

// MARK: - Inline Tab Picker

/// A compact row of section icons for the navigation bar's leading slot, so
/// switching sections costs no vertical space at all.
///
/// Deliberately has no glass background of its own: the navigation bar already
/// provides one, and stacking a second tinted layer on top reads as muddy.
/// The selected icon's crimson capsule is what defines the control.
struct InlineTabPicker<Tab: Hashable>: View {
    @Binding var selectedTab: Tab
    let tabs: [InlineTab<Tab>]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(tabs, id: \.value) { tab in
                InlineTabButton(
                    title: tab.title,
                    icon: tab.icon,
                    isSelected: selectedTab == tab.value
                ) {
                    withAnimation(.snappy(duration: 0.25)) {
                        selectedTab = tab.value
                    }
                }
            }
        }
    }
}

struct InlineTab<Tab: Hashable>: Identifiable {
    let title: String
    let icon: String
    let value: Tab

    var id: Tab { value }
}

// MARK: - Inline Tab Button

struct InlineTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 40, height: 28)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor.opacity(0.9) : .clear)
                )
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}
