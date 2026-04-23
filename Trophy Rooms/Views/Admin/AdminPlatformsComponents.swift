import SwiftUI

struct AdminPlatformsListContent: View {
    let isLoading: Bool
    let errorMessage: String?
    let platforms: [AdminPlatform]
    let isSelecting: Bool
    let selectedIds: Set<String>
    let onToggleSelection: (String) -> Void
    let onTapPlatform: (AdminPlatform) -> Void
    let onEdit: (AdminPlatform) -> Void
    let onDelete: (AdminPlatform) -> Void

    var body: some View {
        if isLoading && platforms.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if let errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
        } else {
            ForEach(platforms) { platform in
                AdminPlatformRow(
                    platform: platform,
                    isSelecting: isSelecting,
                    isSelected: selectedIds.contains(platform.id),
                    onToggleSelection: { onToggleSelection(platform.id) },
                    onTap: { onTapPlatform(platform) },
                    onEdit: { onEdit(platform) },
                    onDelete: { onDelete(platform) }
                )
            }
        }
    }
}

private struct AdminPlatformRow: View {
    let platform: AdminPlatform
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
                Text(platform.name)
                    .font(.headline)
                Text(platform.slug)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
