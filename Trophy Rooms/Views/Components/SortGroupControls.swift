import SwiftUI

// MARK: - Sort Option Protocol

protocol SortOptionProtocol: CaseIterable, Identifiable, Hashable where AllCases: RandomAccessCollection {
    var title: String { get }
    var shortTitle: String { get }
}

// MARK: - Platform Section Header

struct PlatformSectionHeader: View {
    let name: String?
    let slug: String?
    let count: Int
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                if let slug = slug {
                    PlatformIcon(slug: slug, size: 16)
                }
                Text(name ?? "Other")
                    .font(.headline)
                Spacer()
                Text("\(count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// Helper for tracking expanded state
class ExpandedSectionsState: ObservableObject {
    @Published var expandedSections: Set<String> = []

    func isExpanded(_ id: String) -> Bool {
        expandedSections.contains(id)
    }

    func toggle(_ id: String) {
        if expandedSections.contains(id) {
            expandedSections.remove(id)
        } else {
            expandedSections.insert(id)
        }
    }

    func expandAll(_ ids: [String]) {
        expandedSections = Set(ids)
    }
}

// MARK: - Sort Group Controls

struct SortGroupControls<T: SortOptionProtocol>: View {
    @Binding var selectedSortOption: T
    @Binding var groupByPlatform: Bool
    let onSortChanged: () -> Void

    var body: some View {
        HStack {
            // Sort menu
            Menu {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Button {
                        selectedSortOption = option
                        onSortChanged()
                    } label: {
                        HStack {
                            Text(option.title)
                            if selectedSortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(selectedSortOption.shortTitle)
                        .font(.subheadline)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }

            Spacer()

            // Group by platform toggle
            Button {
                groupByPlatform.toggle()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: groupByPlatform ? "rectangle.3.group.fill" : "rectangle.3.group")
                    Text("Group")
                        .font(.subheadline)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(groupByPlatform ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(groupByPlatform ? .white : .primary)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
