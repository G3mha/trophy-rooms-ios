import SwiftUI

// MARK: - Stat Item

struct StatItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
}

// MARK: - Collapsible Stats Bar

struct CollapsibleStatsBar: View {
    let stats: [StatItem]
    let collapsedSummary: String
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed summary row (always visible, tappable)
            Button {
                Motion.animate(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(collapsedSummary)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded stat cards
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(stats) { stat in
                            StatCard(
                                title: stat.title,
                                value: stat.value,
                                icon: stat.icon,
                                color: stat.color
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Cabinet.card)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 76)
        .padding(.vertical, 8)
        .background(Cabinet.canvas)
        .cornerRadius(12)
    }
}
