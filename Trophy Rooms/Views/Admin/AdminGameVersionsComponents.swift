import SwiftUI

struct AdminGameVersionsGameSelectionSection: View {
    @Binding var selectedGame: GameSummary?

    var body: some View {
        Section {
            GameSelectorField(
                title: "Game",
                selectedGame: $selectedGame
            )
        } header: {
            Text("Select Game")
        }
    }
}

struct AdminGameVersionsListSection: View {
    let selectedGame: GameSummary?
    let versions: [GameVersion]
    let isLoading: Bool
    let errorMessage: String?
    let isSelecting: Bool
    let selectedIds: Set<String>
    let onTapVersion: (GameVersion) -> Void
    let onToggleSelection: (String) -> Void
    let onEdit: (GameVersion) -> Void
    let onDelete: (GameVersion) -> Void
    let onSetDefault: (GameVersion) -> Void

    var body: some View {
        if selectedGame != nil {
            Section {
                if isLoading && versions.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                } else if versions.isEmpty {
                    Text("No versions found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(versions, id: \.id) { version in
                        AdminGameVersionRow(
                            version: version,
                            isSelecting: isSelecting,
                            isSelected: selectedIds.contains(version.id),
                            onTap: { onTapVersion(version) },
                            onToggleSelection: { onToggleSelection(version.id) },
                            onEdit: { onEdit(version) },
                            onDelete: { onDelete(version) },
                            onSetDefault: { onSetDefault(version) }
                        )
                    }
                }
            } header: {
                Text("Versions")
            } footer: {
                if !versions.isEmpty {
                    Text("Swipe left to edit/delete, swipe right to set as default. Default version cannot be deleted.")
                }
            }
        }
    }
}

private struct AdminGameVersionRow: View {
    let version: GameVersion
    let isSelecting: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleSelection: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSetDefault: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray)
                    .onTapGesture { onToggleSelection() }
            }

            coverImage

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(version.name)
                        .font(.headline)
                        .lineLimit(1)
                    if version.isDefault {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }

                if !uniquePlatforms.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(uniquePlatforms.prefix(6), id: \.id) { platform in
                            if let slug = platform.slug {
                                PlatformIcon(slug: slug, size: 14)
                            }
                        }
                        if uniquePlatforms.count > 6 {
                            Text("+\(uniquePlatforms.count - 6)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let dlcs = version.dlcs, !dlcs.isEmpty {
                    Text("\(dlcs.count) DLC included")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text("\(version.achievementSetCount ?? 0) sets")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .swipeActions(edge: .trailing) {
            if !isSelecting {
                if !version.isDefault {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }

                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
        .swipeActions(edge: .leading) {
            if !isSelecting && !version.isDefault {
                Button {
                    onSetDefault()
                } label: {
                    Label("Set Default", systemImage: "star")
                }
                .tint(.yellow)
            }
        }
    }

    private var uniquePlatforms: [Platform] {
        guard let games = version.games, !games.isEmpty else { return [] }
        return Array(
            Dictionary(grouping: games.compactMap { $0.platform }, by: { $0.id })
                .compactMap { $0.value.first }
        )
    }

    @ViewBuilder
    private var coverImage: some View {
        if let coverUrl = version.effectiveCoverUrl, let url = URL(string: coverUrl) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
        }
    }
}
