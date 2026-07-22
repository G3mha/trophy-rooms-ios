import SwiftUI

// MARK: - Inline Tab Picker

struct InlineTabPicker<Tab: Hashable>: View {
    @Binding var selectedTab: Tab
    let tabs: [InlineTab<Tab>]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.value) { tab in
                InlineTabButton(
                    title: tab.title,
                    icon: tab.icon,
                    isSelected: selectedTab == tab.value
                ) {
                    withAnimation {
                        selectedTab = tab.value
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
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
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
