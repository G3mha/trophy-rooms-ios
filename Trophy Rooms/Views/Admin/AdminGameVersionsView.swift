import SwiftUI

struct AdminGameVersionsView: View {
    @StateObject private var viewModel = AdminGameVersionsViewModel()
    @StateObject private var screenState = AdminGameVersionsScreenState()

    private var selectedGameFamilyId: String? {
        screenState.selectedGame?.gameFamilyId
    }

    private var nonDefaultSelectedIds: [String] {
        screenState.nonDefaultSelectedIds(in: viewModel.versions)
    }

    var body: some View {
        List {
            AdminGameVersionsGameSelectionSection(selectedGame: $screenState.selectedGame)

            AdminGameVersionsListSection(
                selectedGame: screenState.selectedGame,
                versions: viewModel.versions,
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                isSelecting: screenState.isSelecting,
                selectedIds: screenState.selectedIds,
                onTapVersion: { version in
                    if screenState.isSelecting {
                        screenState.toggleSelection(version.id)
                    } else {
                        screenState.versionToEdit = version
                    }
                },
                onToggleSelection: { screenState.toggleSelection($0) },
                onEdit: { screenState.versionToEdit = $0 },
                onDelete: {
                    screenState.versionToDelete = $0
                    screenState.showingDeleteConfirmation = true
                },
                onSetDefault: {
                    screenState.versionToSetDefault = $0
                    screenState.showingSetDefaultConfirmation = true
                }
            )
        }
        .navigationTitle("Game Versions")
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
                                Label("Add Version", systemImage: "plus")
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
            if screenState.isSelecting && !nonDefaultSelectedIds.isEmpty {
                Button(role: .destructive) {
                    screenState.showingBulkDeleteConfirmation = true
                } label: {
                    Label("Delete \(nonDefaultSelectedIds.count)", systemImage: "trash")
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
                await viewModel.fetchVersions(gameFamilyId: selectedGameFamilyId)
            }
        }
        .onChange(of: screenState.selectedGame) { _, newValue in
            if let gameFamilyId = newValue?.gameFamilyId {
                Task {
                    await viewModel.fetchVersions(gameFamilyId: gameFamilyId)
                }
            } else {
                viewModel.versions = []
            }
            screenState.finishSelection()
        }
        .sheet(isPresented: $screenState.showingCreateSheet) {
            if let selectedGameFamilyId {
                AdminGameVersionFormSheet(
                    viewModel: viewModel,
                    gameFamilyId: selectedGameFamilyId,
                    version: nil
                )
            }
        }
        .sheet(item: $screenState.versionToEdit) { version in
            if let selectedGameFamilyId {
                AdminGameVersionFormSheet(
                    viewModel: viewModel,
                    gameFamilyId: selectedGameFamilyId,
                    version: version
                )
            }
        }
        .alert("Delete Version", isPresented: $screenState.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                screenState.versionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let version = screenState.versionToDelete, let selectedGameFamilyId {
                    Task {
                        _ = await viewModel.deleteVersion(id: version.id, gameFamilyId: selectedGameFamilyId)
                        screenState.versionToDelete = nil
                    }
                }
            }
        } message: {
            if let version = screenState.versionToDelete {
                Text("Are you sure you want to delete \"\(version.name)\"? This action cannot be undone.")
            }
        }
        .alert("Set Default Version", isPresented: $screenState.showingSetDefaultConfirmation) {
            Button("Cancel", role: .cancel) {
                screenState.versionToSetDefault = nil
            }
            Button("Set Default") {
                if let version = screenState.versionToSetDefault, let selectedGameFamilyId {
                    Task {
                        _ = await viewModel.setDefaultVersion(id: version.id, gameFamilyId: selectedGameFamilyId)
                        screenState.versionToSetDefault = nil
                    }
                }
            }
        } message: {
            if let version = screenState.versionToSetDefault {
                Text("Set \"\(version.name)\" as the default version for this game?")
            }
        }
        .alert("Delete Versions", isPresented: $screenState.showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let selectedGameFamilyId {
                    Task {
                        _ = await viewModel.bulkDeleteVersions(
                            ids: nonDefaultSelectedIds,
                            gameFamilyId: selectedGameFamilyId
                        )
                        screenState.finishSelection()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \(nonDefaultSelectedIds.count) version(s)? Default versions will be skipped. This action cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        AdminGameVersionsView()
    }
}
