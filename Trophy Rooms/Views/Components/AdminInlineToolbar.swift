import SwiftUI

/// Floating admin toolbar that appears when viewing entity detail pages
/// Uses native iOS 26 glass effect and Menu for actions
struct AdminInlineToolbar: View {
    @EnvironmentObject private var inlineAdminContext: InlineAdminContext
    @StateObject private var gamesViewModel = AdminGamesViewModel()
    @StateObject private var state = AdminInlineToolbarState()

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
        let controller = AdminInlineToolbarController(
            entity: entity,
            gamesViewModel: gamesViewModel
        )

        Menu {
            AdminInlineToolbarMenuContent(
                entity: entity,
                onEditGame: state.presentEdit,
                onCloneGame: state.presentClone,
                onDelete: state.presentDeleteConfirmation
            )
        } label: {
            AdminInlineToolbarLabel()
        }
        .menuStyle(.automatic)
        .sheet(isPresented: $state.showEditSheet) {
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
        .sheet(isPresented: $state.showCloneSheet) {
            if let entity = inlineAdminContext.currentEntity, entity.type == .game {
                GameCloneSheet(
                    gameId: entity.id,
                    gameTitle: entity.title,
                    currentPlatformId: entity.platformId,
                    viewModel: gamesViewModel
                )
            }
        }
        .alert(controller.deleteAlertTitle, isPresented: $state.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteCurrentEntity(controller: controller)
            }
        } message: {
            Text(controller.deleteAlertMessage)
        }
    }

    // MARK: - Delete Action

    private func deleteCurrentEntity(controller: AdminInlineToolbarController) {
        state.isDeleting = true

        Task {
            _ = await controller.deleteCurrentEntity {
                inlineAdminContext.clearEntity()
            }

            await MainActor.run {
                state.isDeleting = false
            }
        }
    }
}

#Preview {
    AdminInlineToolbar()
        .environmentObject(InlineAdminContext())
}
