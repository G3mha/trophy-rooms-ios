import SwiftUI

struct AdminDLCsView: View {
    @StateObject private var viewModel = AdminDLCsViewModel()
    @StateObject private var platformsViewModel = AdminPlatformsViewModel()
    @StateObject private var screenState = AdminDLCsScreenState()

    private var selectedGameFamilyId: String? {
        screenState.selectedGame?.gameFamilyId
    }

    private var availablePlatforms: [Platform] {
        platformsViewModel.platforms.map { Platform(id: $0.id, name: $0.name, slug: $0.slug) }
    }

    var body: some View {
        List {
            AdminDLCGameSelectionSection(selectedGame: $screenState.selectedGame)

            AdminDLCListSection(
                selectedGame: screenState.selectedGame,
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                dlcs: viewModel.dlcs,
                isSelecting: screenState.isSelecting,
                selectedIds: screenState.selectedIds,
                onTapDLC: { dlc in
                    if screenState.isSelecting {
                        screenState.toggleSelection(dlc.id)
                    } else {
                        screenState.dlcToEdit = dlc
                    }
                },
                onToggleSelection: { screenState.toggleSelection($0) },
                onEdit: { screenState.dlcToEdit = $0 },
                onDelete: { screenState.presentDelete(for: $0) }
            )
        }
        .navigationTitle("DLCs & Expansions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if screenState.selectedGame != nil {
                    if screenState.isSelecting {
                        Button("Done") {
                            screenState.finishSelection()
                        }
                    } else {
                        Menu {
                            Button {
                                screenState.showingCreateSheet = true
                            } label: {
                                Label("Add DLC", systemImage: "plus")
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
            if let selectedGameFamilyId {
                await viewModel.fetchDLCs(gameFamilyId: selectedGameFamilyId)
            }
        }
        .onChange(of: screenState.selectedGame) { _, newValue in
            if let gameFamilyId = newValue?.gameFamilyId {
                Task {
                    await viewModel.fetchDLCs(gameFamilyId: gameFamilyId)
                }
            } else {
                viewModel.dlcs = []
            }
            screenState.finishSelection()
        }
        .sheet(isPresented: $screenState.showingCreateSheet) {
            if let selectedGameFamilyId {
                AdminDLCFormSheet(
                    viewModel: viewModel,
                    gameFamilyId: selectedGameFamilyId,
                    dlc: nil,
                    availablePlatforms: availablePlatforms
                )
            }
        }
        .sheet(item: $screenState.dlcToEdit) { dlc in
            if let selectedGameFamilyId {
                AdminDLCFormSheet(
                    viewModel: viewModel,
                    gameFamilyId: selectedGameFamilyId,
                    dlc: dlc,
                    availablePlatforms: availablePlatforms
                )
            }
        }
        .alert("Delete DLC", isPresented: $screenState.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                screenState.dlcToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let dlc = screenState.dlcToDelete, let selectedGameFamilyId {
                    Task {
                        _ = await viewModel.deleteDLC(id: dlc.id, gameFamilyId: selectedGameFamilyId)
                        screenState.dlcToDelete = nil
                    }
                }
            }
        } message: {
            if let dlc = screenState.dlcToDelete {
                Text("Are you sure you want to delete \"\(dlc.name)\"? This action cannot be undone.")
            }
        }
        .task {
            await platformsViewModel.fetchPlatforms()
        }
        .alert("Delete DLCs", isPresented: $screenState.showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let selectedGameFamilyId {
                    Task {
                        _ = await viewModel.bulkDeleteDLCs(
                            ids: Array(screenState.selectedIds),
                            gameFamilyId: selectedGameFamilyId
                        )
                        screenState.finishSelection()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \(screenState.selectedIds.count) DLC(s)? This action cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        AdminDLCsView()
    }
}
