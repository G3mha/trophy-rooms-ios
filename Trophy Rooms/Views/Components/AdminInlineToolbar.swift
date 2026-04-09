import SwiftUI

/// Floating admin toolbar that appears when viewing entity detail pages
/// Uses native iOS 26 glass effect and Menu for actions
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
            adminMenu(for: entity)
                .task {
                    await gamesViewModel.fetchPlatforms()
                }
        }
    }

    // MARK: - Admin Menu

    @ViewBuilder
    private func adminMenu(for entity: AdminContextEntity) -> some View {
        Menu {
            // Entity info section (non-interactive header)
            Section {
                Label {
                    VStack(alignment: .leading) {
                        Text(entity.title)
                        if let platformName = entity.platformName {
                            Text(platformName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: {
                    Image(systemName: iconName(for: entity.type))
                }
            }

            // Actions section
            Section {
                switch entity.type {
                case .game:
                    gameMenuActions()
                case .bundle:
                    bundleMenuActions()
                case .dlc:
                    dlcMenuActions()
                case .achievementSet:
                    achievementSetMenuActions()
                }
            }

            // Destructive section
            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        } label: {
            adminMenuLabel
        }
        .menuStyle(.automatic)
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
        .alert("Delete \(entityTypeName(for: entity.type))", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteCurrentEntity()
            }
        } message: {
            Text("Are you sure you want to delete \"\(entity.title)\"? This action cannot be undone.")
        }
    }

    // MARK: - Menu Actions

    @ViewBuilder
    private func gameMenuActions() -> some View {
        Button {
            showEditSheet = true
        } label: {
            Label("Edit Game", systemImage: "pencil")
        }

        Button {
            showCloneSheet = true
        } label: {
            Label("Clone to Platform", systemImage: "doc.on.doc")
        }
    }

    @ViewBuilder
    private func bundleMenuActions() -> some View {
        Button {
            // TODO: Implement bundle edit
        } label: {
            Label("Edit Bundle", systemImage: "pencil")
        }
    }

    @ViewBuilder
    private func dlcMenuActions() -> some View {
        Button {
            // TODO: Implement DLC edit
        } label: {
            Label("Edit DLC", systemImage: "pencil")
        }
    }

    @ViewBuilder
    private func achievementSetMenuActions() -> some View {
        Button {
            // TODO: Implement achievement set edit
        } label: {
            Label("Edit Set", systemImage: "pencil")
        }
    }

    // MARK: - Menu Label

    @ViewBuilder
    private var adminMenuLabel: some View {
        if #available(iOS 26.0, *) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 56, height: 56)
                .glassEffect(.regular.tint(.blue.opacity(0.3)))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        } else {
            // Fallback for earlier iOS versions
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Helpers

    private func iconName(for type: AdminEntityType) -> String {
        switch type {
        case .game: return "gamecontroller.fill"
        case .bundle: return "shippingbox.fill"
        case .dlc: return "puzzlepiece.extension.fill"
        case .achievementSet: return "star.fill"
        }
    }

    private func entityTypeName(for type: AdminEntityType) -> String {
        switch type {
        case .game: return "Game"
        case .bundle: return "Bundle"
        case .dlc: return "DLC"
        case .achievementSet: return "Achievement Set"
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
