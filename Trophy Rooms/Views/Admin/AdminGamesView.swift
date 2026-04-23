import SwiftUI

struct AdminGamesView: View {
    @StateObject private var viewModel = AdminGamesViewModel()
    @StateObject private var screenState = AdminGamesScreenState()

    var body: some View {
        List {
            AdminGamesPaginationSection(
                viewModel: viewModel,
                selectedPageSize: $screenState.selectedPageSize
            )

            AdminGamesListContent(
                viewModel: viewModel,
                isSelecting: screenState.isSelecting,
                selectedIds: screenState.selectedIds,
                onToggleSelection: screenState.toggleSelection,
                onEdit: { screenState.gameToEdit = $0 },
                onDelete: screenState.presentDelete,
                onClone: screenState.presentClone,
                onAddPlatform: { screenState.groupToAddPlatform = $0 },
                deleteActionLabel: screenState.deleteActionLabel(for:)
            )
        }
        .searchable(text: $viewModel.searchText, prompt: "Search games")
        .onSubmit(of: .search) {
            Task {
                await viewModel.search()
            }
        }
        .onChange(of: viewModel.searchText) { _, newValue in
            if newValue.isEmpty {
                Task {
                    await viewModel.fetchGames(page: 1)
                }
            }
        }
        .onChange(of: screenState.selectedPageSize) {
            Task {
                await viewModel.setPageSize(screenState.selectedPageSize)
            }
        }
        .navigationTitle("Games")
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
                            Label("Add Game", systemImage: "plus")
                        }

                        Button {
                            screenState.isSelecting = true
                        } label: {
                            Label("Select", systemImage: "checkmark.circle")
                        }

                        Divider()

                        Button {
                            viewModel.isGrouped.toggle()
                        } label: {
                            if viewModel.isGrouped {
                                Label("Show Flat List", systemImage: "list.bullet")
                            } else {
                                Label("Group by Family", systemImage: "rectangle.3.group")
                            }
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
            await viewModel.fetchGames(page: viewModel.currentPage)
        }
        .task {
            await viewModel.fetchGames(page: 1)
            await viewModel.fetchPlatforms()
        }
        .sheet(isPresented: $screenState.showingCreateSheet) {
            AdminGameFormSheet(viewModel: viewModel, game: nil)
        }
        .sheet(item: $screenState.gameToEdit) { game in
            AdminGameFormSheet(viewModel: viewModel, game: game)
        }
        .alert(screenState.deleteAlertTitle, isPresented: $screenState.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                screenState.gameToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let game = screenState.gameToDelete {
                    Task {
                        _ = await viewModel.deleteGame(id: game.id)
                        screenState.gameToDelete = nil
                    }
                }
            }
        } message: {
            if let game = screenState.gameToDelete {
                Text(screenState.deleteAlertMessage(for: game))
            }
        }
        .alert("Delete \(screenState.selectedIds.count) Games", isPresented: $screenState.showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.bulkDeleteGames(ids: Array(screenState.selectedIds))
                    screenState.finishSelection()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(screenState.selectedIds.count) game(s)? This will also delete all related achievement sets and achievements. This action cannot be undone.")
        }
        .sheet(isPresented: $screenState.showingCloneSheet) {
            if let game = screenState.gameToClone {
                CloneGameSheet(viewModel: viewModel, game: game) {
                    screenState.showingCloneSheet = false
                    screenState.gameToClone = nil
                }
            }
        }
        .sheet(item: $screenState.groupToAddPlatform) { group in
            if let gameFamilyId = group.gameFamilyId {
                AddPlatformSheet(
                    viewModel: viewModel,
                    gameFamilyId: gameFamilyId,
                    gameTitle: group.title,
                    existingPlatformIds: Set(group.games.compactMap { $0.platformId })
                ) {
                    screenState.groupToAddPlatform = nil
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AdminGamesView()
    }
}
