import SwiftUI

/// Floating admin toolbar that appears when viewing entity detail pages
/// Shows context-specific admin actions for the current entity
struct AdminInlineToolbar: View {
    @EnvironmentObject private var inlineAdminContext: InlineAdminContext
    @StateObject private var gamesViewModel = AdminGamesViewModel()

    // Sheet presentation states
    @State private var showEditSheet = false
    @State private var showCloneSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false

    var body: some View {
        if let entity = inlineAdminContext.currentEntity {
            if inlineAdminContext.isToolbarExpanded {
                expandedToolbar(for: entity)
            } else {
                collapsedToolbar
            }
        }
    }

    // MARK: - Collapsed State

    private var collapsedToolbar: some View {
        Button {
            inlineAdminContext.toggleToolbar()
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Expanded State

    private func expandedToolbar(for entity: AdminContextEntity) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            // Entity header
            HStack(spacing: 12) {
                // Entity icon/cover
                entityIcon(for: entity)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entity.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    if let platformName = entity.platformName {
                        HStack(spacing: 4) {
                            if let slug = entity.platformSlug {
                                PlatformIcon(slug: slug, size: 12)
                            }
                            Text(platformName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Action buttons based on entity type
            VStack(spacing: 0) {
                switch entity.type {
                case .game:
                    gameActions(for: entity)
                case .bundle:
                    bundleActions(for: entity)
                case .dlc:
                    dlcActions(for: entity)
                case .achievementSet:
                    achievementSetActions(for: entity)
                }
            }

            Divider()

            // Collapse button
            Button {
                inlineAdminContext.toggleToolbar()
            } label: {
                HStack {
                    Text("Collapse")
                        .font(.subheadline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
        .frame(width: 260)
        .sheet(isPresented: $showEditSheet) {
            if let entity = inlineAdminContext.currentEntity, entity.type == .game {
                AdminGameFormSheetWrapper(
                    gameId: entity.id,
                    viewModel: gamesViewModel,
                    onSave: {
                        NotificationCenter.default.post(name: .adminGameDidUpdate, object: nil)
                    }
                )
            }
        }
        .sheet(isPresented: $showCloneSheet) {
            if let entity = inlineAdminContext.currentEntity, entity.type == .game {
                GameCloneSheet(
                    gameId: entity.id,
                    gameTitle: entity.title,
                    currentPlatformId: entity.platformId,
                    viewModel: gamesViewModel
                )
            }
        }
        .alert("Delete Game", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteCurrentEntity()
            }
        } message: {
            if let entity = inlineAdminContext.currentEntity {
                Text("Are you sure you want to delete \"\(entity.title)\"? This action cannot be undone.")
            }
        }
        .task {
            await gamesViewModel.fetchPlatforms()
        }
    }

    // MARK: - Entity Icon

    private func entityIcon(for entity: AdminContextEntity) -> some View {
        Group {
            if let coverUrl = entity.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    entityPlaceholderIcon(for: entity)
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                entityPlaceholderIcon(for: entity)
            }
        }
    }

    private func entityPlaceholderIcon(for entity: AdminContextEntity) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.systemGray5))
            .frame(width: 40, height: 40)
            .overlay {
                Image(systemName: iconName(for: entity.type))
                    .foregroundStyle(.secondary)
            }
    }

    private func iconName(for type: AdminEntityType) -> String {
        switch type {
        case .game: return "gamecontroller.fill"
        case .bundle: return "shippingbox.fill"
        case .dlc: return "puzzlepiece.extension.fill"
        case .achievementSet: return "star.fill"
        }
    }

    // MARK: - Game Actions

    private func gameActions(for entity: AdminContextEntity) -> some View {
        Group {
            ActionButton(title: "Edit Game", icon: "pencil") {
                showEditSheet = true
            }

            ActionButton(title: "Clone to Platform", icon: "doc.on.doc") {
                showCloneSheet = true
            }

            ActionButton(title: "Delete", icon: "trash", isDestructive: true) {
                showDeleteConfirmation = true
            }
        }
    }

    // MARK: - Bundle Actions

    private func bundleActions(for entity: AdminContextEntity) -> some View {
        Group {
            ActionButton(title: "Edit Bundle", icon: "pencil") {
                // TODO: Implement bundle edit
            }

            ActionButton(title: "Delete", icon: "trash", isDestructive: true) {
                showDeleteConfirmation = true
            }
        }
    }

    // MARK: - DLC Actions

    private func dlcActions(for entity: AdminContextEntity) -> some View {
        Group {
            ActionButton(title: "Edit DLC", icon: "pencil") {
                // TODO: Implement DLC edit
            }

            ActionButton(title: "Delete", icon: "trash", isDestructive: true) {
                showDeleteConfirmation = true
            }
        }
    }

    // MARK: - Achievement Set Actions

    private func achievementSetActions(for entity: AdminContextEntity) -> some View {
        Group {
            ActionButton(title: "Edit Set", icon: "pencil") {
                // TODO: Implement achievement set edit
            }

            ActionButton(title: "Delete", icon: "trash", isDestructive: true) {
                showDeleteConfirmation = true
            }
        }
    }

    // MARK: - Delete Action

    private func deleteCurrentEntity() {
        guard let entity = inlineAdminContext.currentEntity else { return }

        isDeleting = true

        Task {
            var success = false

            switch entity.type {
            case .game:
                success = await gamesViewModel.deleteGame(id: entity.id)
            case .bundle, .dlc, .achievementSet:
                // TODO: Implement other entity deletions
                break
            }

            await MainActor.run {
                isDeleting = false
                if success {
                    inlineAdminContext.clearEntity()
                    NotificationCenter.default.post(name: .adminGameDidDelete, object: nil)
                }
            }
        }
    }
}

// MARK: - Action Button Component

private struct ActionButton: View {
    let title: String
    let icon: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .foregroundStyle(isDestructive ? .red : .primary)
        }
    }
}

// MARK: - Admin Game Form Sheet Wrapper

/// Wrapper to load game data before showing the edit form
private struct AdminGameFormSheetWrapper: View {
    let gameId: String
    @ObservedObject var viewModel: AdminGamesViewModel
    var onSave: (() -> Void)?

    @State private var gameToEdit: AdminGameItem?
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading game...")
            } else if let game = gameToEdit {
                AdminGameFormSheet(
                    viewModel: viewModel,
                    game: game,
                    onSave: onSave
                )
            } else {
                Text("Game not found")
            }
        }
        .task {
            await loadGame()
        }
    }

    private func loadGame() async {
        // Fetch the game data to edit
        await viewModel.fetchGame(id: gameId)
        await MainActor.run {
            gameToEdit = viewModel.gameToEdit
            isLoading = false
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let adminGameDidUpdate = Notification.Name("adminGameDidUpdate")
    static let adminGameDidDelete = Notification.Name("adminGameDidDelete")
}

#Preview {
    AdminInlineToolbar()
        .environmentObject(InlineAdminContext())
}
