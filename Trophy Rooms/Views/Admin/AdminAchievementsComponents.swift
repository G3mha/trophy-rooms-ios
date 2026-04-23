import SwiftUI

struct AdminAchievementsSetSelectorButton: View {
    let currentSetTitle: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Achievement Set")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(currentSetTitle.isEmpty ? "Select a set..." : currentSetTitle)
                        .font(.headline)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
        }
        .buttonStyle(.plain)
    }
}

struct AdminAchievementsContent: View {
    let selectedSetId: String
    let isLoading: Bool
    let errorMessage: String?
    let achievements: [AdminAchievement]
    let isSelecting: Bool
    let selectedIds: Set<String>
    let onToggleSelection: (String) -> Void
    let onTapAchievement: (AdminAchievement) -> Void
    let onEdit: (AdminAchievement) -> Void
    let onDelete: (AdminAchievement) -> Void

    var body: some View {
        if selectedSetId.isEmpty {
            ContentUnavailableView(
                "No Set Selected",
                systemImage: "list.bullet.rectangle",
                description: Text("Select an achievement set to view and manage achievements")
            )
        } else if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage {
            ContentUnavailableView(
                "Error",
                systemImage: "exclamationmark.triangle",
                description: Text(errorMessage)
            )
        } else if achievements.isEmpty {
            ContentUnavailableView(
                "No Achievements",
                systemImage: "star",
                description: Text("This set has no achievements yet. Add some!")
            )
        } else {
            List {
                ForEach(achievements) { achievement in
                    AdminAchievementRow(
                        achievement: achievement,
                        isSelecting: isSelecting,
                        isSelected: selectedIds.contains(achievement.id),
                        onTap: { onTapAchievement(achievement) },
                        onToggleSelection: { onToggleSelection(achievement.id) },
                        onEdit: { onEdit(achievement) },
                        onDelete: { onDelete(achievement) }
                    )
                }
            }
        }
    }
}

private struct AdminAchievementRow: View {
    let achievement: AdminAchievement
    let isSelecting: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleSelection: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray)
                    .onTapGesture { onToggleSelection() }
            }

            AsyncImage(url: achievement.iconUrl.flatMap { URL(string: $0) }) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(tierColor(achievement.tier))
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .lineLimit(1)
                if let description = achievement.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 8) {
                    Text("\(achievement.points) pts")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    if let tier = achievement.tier {
                        Text(tier.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(tierColor(tier).opacity(0.2))
                            .cornerRadius(4)
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

    private func tierColor(_ tier: AchievementTier?) -> Color {
        guard let tier else { return .gray }
        switch tier {
        case .BRONZE: return .brown
        case .SILVER: return .gray
        case .GOLD: return .yellow
        case .PLATINUM: return Color(red: 0.898, green: 0.894, blue: 0.886)
        }
    }
}

struct AdminAchievementsSetPickerSheet: View {
    @ObservedObject var viewModel: AdminAchievementsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredSets: [AdminAchievementSet] {
        if searchText.isEmpty {
            return viewModel.achievementSets
        }
        return viewModel.achievementSets.filter { set in
            set.title.localizedCaseInsensitiveContains(searchText) ||
            (set.gameFamily?.title.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredSets) { set in
                Button {
                    Task {
                        await viewModel.fetchAchievements(setId: set.id)
                        dismiss()
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(set.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if let gameFamily = set.gameFamily {
                            Text(gameFamily.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let count = set.achievementCount {
                            Text("\(count) achievements")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search sets")
            .navigationTitle("Select Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
