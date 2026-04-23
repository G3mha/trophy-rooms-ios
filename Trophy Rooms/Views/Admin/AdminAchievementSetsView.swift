import SwiftUI

struct AdminAchievementSetsView: View {
    @StateObject private var viewModel = AdminAchievementSetsViewModel()
    @StateObject private var screenState = AdminAchievementSetsScreenState()

    var body: some View {
        List {
            AdminAchievementSetsListContent(
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                achievementSets: viewModel.filteredSets,
                isSelecting: screenState.isSelecting,
                selectedIds: screenState.selectedIds,
                onToggleSelection: { screenState.toggleSelection($0) },
                onTapSet: { set in
                    if screenState.isSelecting {
                        screenState.toggleSelection(set.id)
                    } else {
                        screenState.setToEdit = set
                    }
                },
                onEdit: { screenState.setToEdit = $0 },
                onDelete: { screenState.presentDelete(for: $0) }
            )
        }
        .searchable(text: $viewModel.searchText, prompt: "Search sets or games")
        .navigationTitle("Achievement Sets")
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
                            Label("Add Set", systemImage: "plus")
                        }

                        Button {
                            screenState.isSelecting = true
                        } label: {
                            Label("Select", systemImage: "checkmark.circle")
                        }
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
        .refreshable {
            await viewModel.fetchAchievementSets()
        }
        .task {
            await viewModel.fetchAchievementSets()
            await viewModel.fetchGames()
        }
        .sheet(isPresented: $screenState.showingCreateSheet) {
            AdminSetFormSheet(viewModel: viewModel, achievementSet: nil)
        }
        .sheet(item: $screenState.setToEdit) { set in
            AdminSetFormSheet(viewModel: viewModel, achievementSet: set)
        }
        .alert("Delete Achievement Set", isPresented: $screenState.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                screenState.setToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let set = screenState.setToDelete {
                    Task {
                        _ = await viewModel.deleteAchievementSet(id: set.id)
                        screenState.setToDelete = nil
                    }
                }
            }
        } message: {
            if let set = screenState.setToDelete {
                Text("Are you sure you want to delete \"\(set.title)\"? This will also delete all achievements in this set. This action cannot be undone.")
            }
        }
        .alert("Delete \(screenState.selectedIds.count) Sets", isPresented: $screenState.showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.bulkDeleteAchievementSets(ids: Array(screenState.selectedIds))
                    screenState.finishSelection()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(screenState.selectedIds.count) achievement set(s)? This will also delete all achievements in these sets. This action cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        AdminAchievementSetsView()
    }
}
