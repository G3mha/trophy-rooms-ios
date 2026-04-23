import SwiftUI

struct AdminAchievementsView: View {
    @StateObject private var viewModel = AdminAchievementsViewModel()
    @StateObject private var screenState = AdminAchievementsScreenState()

    var body: some View {
        VStack(spacing: 0) {
            AdminAchievementsSetSelectorButton(
                currentSetTitle: viewModel.currentSetTitle,
                onTap: { screenState.showingSetPicker = true }
            )

            AdminAchievementsContent(
                selectedSetId: viewModel.selectedSetId,
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                achievements: viewModel.achievements,
                isSelecting: screenState.isSelecting,
                selectedIds: screenState.selectedIds,
                onToggleSelection: { screenState.toggleSelection($0) },
                onTapAchievement: { achievement in
                    if screenState.isSelecting {
                        screenState.toggleSelection(achievement.id)
                    } else {
                        screenState.achievementToEdit = achievement
                    }
                },
                onEdit: { screenState.achievementToEdit = $0 },
                onDelete: { screenState.presentDelete(for: $0) }
            )
        }
        .navigationTitle("Achievements")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if screenState.isSelecting {
                    Button("Done") {
                        screenState.finishSelection()
                    }
                } else {
                    Menu {
                        Button {
                            screenState.showingCreateSheet = true
                        } label: {
                            Label("Add Achievement", systemImage: "plus")
                        }
                        .disabled(viewModel.selectedSetId.isEmpty)

                        Button {
                            screenState.showingCSVImportSheet = true
                        } label: {
                            Label("Import CSV", systemImage: "doc.badge.plus")
                        }
                        .disabled(viewModel.selectedSetId.isEmpty)

                        Button {
                            screenState.isSelecting = true
                        } label: {
                            Label("Select", systemImage: "checkmark.circle")
                        }
                        .disabled(viewModel.selectedSetId.isEmpty || viewModel.achievements.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if screenState.isSelecting && !screenState.selectedIds.isEmpty {
                Button(role: .destructive) {
                    screenState.showingBulkDeleteConfirmation = true
                } label: {
                    Label("Delete \(screenState.selectedIds.count)", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding()
                .background(.bar)
            }
        }
        .task {
            await viewModel.fetchAchievementSets()
        }
        .sheet(isPresented: $screenState.showingSetPicker) {
            AdminAchievementsSetPickerSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $screenState.showingCreateSheet) {
            AdminAchievementFormSheet(viewModel: viewModel, achievement: nil)
        }
        .sheet(item: $screenState.achievementToEdit) { achievement in
            AdminAchievementFormSheet(viewModel: viewModel, achievement: achievement)
        }
        .sheet(isPresented: $screenState.showingCSVImportSheet) {
            AdminCSVImportSheet(viewModel: viewModel)
        }
        .alert("Delete Achievement", isPresented: $screenState.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                screenState.achievementToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let achievement = screenState.achievementToDelete {
                    Task {
                        _ = await viewModel.deleteAchievement(id: achievement.id)
                        screenState.achievementToDelete = nil
                    }
                }
            }
        } message: {
            if let achievement = screenState.achievementToDelete {
                Text("Are you sure you want to delete \"\(achievement.title)\"? This action cannot be undone.")
            }
        }
        .alert("Delete \(screenState.selectedIds.count) Achievements", isPresented: $screenState.showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.bulkDeleteAchievements(ids: Array(screenState.selectedIds))
                    screenState.finishSelection()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(screenState.selectedIds.count) achievement(s)? This action cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        AdminAchievementsView()
    }
}
