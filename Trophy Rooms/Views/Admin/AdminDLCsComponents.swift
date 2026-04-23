import SwiftUI

struct AdminDLCGameSelectionSection: View {
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

struct AdminDLCListSection: View {
    let selectedGame: GameSummary?
    let isLoading: Bool
    let errorMessage: String?
    let dlcs: [DLC]
    let isSelecting: Bool
    let selectedIds: Set<String>
    let onTapDLC: (DLC) -> Void
    let onToggleSelection: (String) -> Void
    let onEdit: (DLC) -> Void
    let onDelete: (DLC) -> Void

    var body: some View {
        if selectedGame != nil {
            Section {
                if isLoading && dlcs.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                } else if dlcs.isEmpty {
                    Text("No DLCs found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dlcs, id: \.id) { dlc in
                        AdminDLCRow(
                            dlc: dlc,
                            isSelecting: isSelecting,
                            isSelected: selectedIds.contains(dlc.id),
                            onTap: { onTapDLC(dlc) },
                            onToggleSelection: { onToggleSelection(dlc.id) },
                            onEdit: { onEdit(dlc) },
                            onDelete: { onDelete(dlc) }
                        )
                    }
                }
            } header: {
                Text("DLCs & Expansions")
            } footer: {
                if !dlcs.isEmpty {
                    Text("Swipe left to edit or delete.")
                }
            }
        }
    }
}

private struct AdminDLCRow: View {
    let dlc: DLC
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

            coverImage

            VStack(alignment: .leading, spacing: 4) {
                Text(dlc.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(dlc.slug)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DLCTypeBadge(type: dlc.type)
                }
                if let price = dlc.price {
                    Text(String(format: "$%.2f", price))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if let count = dlc.achievementSetCount, count > 0 {
                Text("\(count) sets")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
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

    @ViewBuilder
    private var coverImage: some View {
        if let coverUrl = dlc.effectiveCoverUrl, let url = URL(string: coverUrl) {
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
