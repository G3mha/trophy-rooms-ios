import SwiftUI

/// Floating admin control that appears when viewing entity detail pages.
/// Collapsed it is a single glass gear; tapping it morphs the glass into a
/// row of entity-scoped action buttons (Liquid Glass container morph).
struct AdminInlineToolbar: View {
    @EnvironmentObject private var inlineAdminContext: InlineAdminContext
    @StateObject private var gamesViewModel = AdminGamesViewModel()
    @StateObject private var state = AdminInlineToolbarState()
    @State private var isExpanded = false
    @Namespace private var glassNamespace

    var body: some View {
        if let entity = inlineAdminContext.currentEntity {
            toolbar(for: entity)
                .task {
                    await gamesViewModel.fetchPlatforms()
                }
                .onChange(of: entity.id) {
                    isExpanded = false
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

        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                if isExpanded {
                    entityBadge(for: entity)
                        .glassEffectID("entity", in: glassNamespace)

                    if entity.type == .game {
                        actionButton(icon: "pencil", tint: .blue) {
                            collapseThen(state.presentEdit)
                        }
                        .glassEffectID("edit", in: glassNamespace)

                        actionButton(icon: "doc.on.doc", tint: .blue) {
                            collapseThen(state.presentClone)
                        }
                        .glassEffectID("clone", in: glassNamespace)
                    }

                    actionButton(icon: "trash", tint: .red) {
                        collapseThen(state.presentDeleteConfirmation)
                    }
                    .glassEffectID("delete", in: glassNamespace)
                }

                Button {
                    withAnimation(.bouncy) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "xmark" : "gearshape.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 56, height: 56)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.tint(.blue.opacity(0.3)).interactive(), in: .circle)
                .glassEffectID("gear", in: glassNamespace)
            }
        }
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

    private func collapseThen(_ action: @escaping () -> Void) {
        withAnimation(.bouncy) {
            isExpanded = false
        }
        action()
    }

    private func entityBadge(for entity: AdminContextEntity) -> some View {
        HStack(spacing: 6) {
            Image(systemName: iconName(for: entity.type))
                .font(.system(size: 12, weight: .semibold))
            Text(entity.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .frame(maxWidth: 160)
        .glassEffect(.regular, in: .capsule)
    }

    private func actionButton(
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
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
