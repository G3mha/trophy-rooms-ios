import SwiftUI

/// Admin bar mounted as a bottom safe-area inset on entity detail pages.
/// Renders nothing (zero inset) for non-admins or when no entity is set, so
/// it never shows an empty surface.
struct AdminInlineToolbar: View {
    @EnvironmentObject private var inlineAdminContext: InlineAdminContext
    @StateObject private var gamesViewModel = AdminGamesViewModel()
    @StateObject private var state = AdminInlineToolbarState()

    var body: some View {
        if inlineAdminContext.canAccessAdmin, let entity = inlineAdminContext.currentEntity {
            toolbar(for: entity)
                .task {
                    await gamesViewModel.fetchPlatforms()
                }
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private func toolbar(for entity: AdminContextEntity) -> some View {
        let controller = AdminInlineToolbarController(
            entity: entity,
            gamesViewModel: gamesViewModel
        )

        HStack(spacing: 12) {
            Image(systemName: iconName(for: entity.type))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 1) {
                Text("Admin")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(entity.title)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if entity.type == .game {
                accessoryButton(icon: "pencil", tint: .primary, action: state.presentEdit)
                accessoryButton(icon: "doc.on.doc", tint: .primary, action: state.presentClone)
            }

            accessoryButton(icon: "trash", tint: .red, action: state.presentDeleteConfirmation)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
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

    // MARK: - Pieces

    private func accessoryButton(
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func iconName(for type: AdminEntityType) -> String {
        switch type {
        case .game: return "gamecontroller.fill"
        case .bundle: return "shippingbox.fill"
        case .dlc: return "puzzlepiece.extension.fill"
        case .achievementSet: return "star.fill"
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
