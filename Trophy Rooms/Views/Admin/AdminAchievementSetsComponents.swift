import SwiftUI

struct AdminAchievementSetsListContent: View {
    let isLoading: Bool
    let errorMessage: String?
    let achievementSets: [AdminAchievementSet]
    let isSelecting: Bool
    let selectedIds: Set<String>
    let onToggleSelection: (String) -> Void
    let onTapSet: (AdminAchievementSet) -> Void
    let onEdit: (AdminAchievementSet) -> Void
    let onDelete: (AdminAchievementSet) -> Void

    var body: some View {
        if isLoading && achievementSets.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if let errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
        } else {
            ForEach(achievementSets) { set in
                AdminAchievementSetRow(
                    set: set,
                    isSelecting: isSelecting,
                    isSelected: selectedIds.contains(set.id),
                    onToggleSelection: { onToggleSelection(set.id) },
                    onTap: { onTapSet(set) },
                    onEdit: { onEdit(set) },
                    onDelete: { onDelete(set) }
                )
            }
        }
    }
}

private struct AdminAchievementSetRow: View {
    let set: AdminAchievementSet
    let isSelecting: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray)
                    .onTapGesture { onToggleSelection() }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(set.title)
                    .font(.headline)
                if let gameFamily = set.gameFamily {
                    Text(gameFamily.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    Text(set.typeEnum.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)

                    Text(set.visibilityEnum.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)

                    if let count = set.achievementCount {
                        Text("\(count) achievements")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .swipeActions(edge: .trailing) {
            if !isSelecting {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
    }
}
