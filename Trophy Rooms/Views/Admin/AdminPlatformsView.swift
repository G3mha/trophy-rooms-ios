import SwiftUI

struct AdminPlatformsView: View {
    @StateObject private var viewModel = AdminPlatformsViewModel()
    @StateObject private var screenState = AdminPlatformsScreenState()

    var body: some View {
        List {
            AdminPlatformsListContent(
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                platforms: viewModel.platforms,
                isSelecting: screenState.isSelecting,
                selectedIds: screenState.selectedIds,
                onToggleSelection: { screenState.toggleSelection($0) },
                onTapPlatform: { platform in
                    if screenState.isSelecting {
                        screenState.toggleSelection(platform.id)
                    } else {
                        screenState.platformToEdit = platform
                    }
                },
                onEdit: { screenState.platformToEdit = $0 },
                onDelete: { screenState.presentDelete(for: $0) }
            )
        }
        .navigationTitle("Platforms")
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
                            Label("Add Platform", systemImage: "plus")
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
            await viewModel.fetchPlatforms()
        }
        .task {
            await viewModel.fetchPlatforms()
        }
        .sheet(isPresented: $screenState.showingCreateSheet) {
            AdminPlatformFormSheet(viewModel: viewModel, platform: nil)
        }
        .sheet(item: $screenState.platformToEdit) { platform in
            AdminPlatformFormSheet(viewModel: viewModel, platform: platform)
        }
        .alert("Delete Platform", isPresented: $screenState.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                screenState.platformToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let platform = screenState.platformToDelete {
                    Task {
                        _ = await viewModel.deletePlatform(id: platform.id)
                        screenState.platformToDelete = nil
                    }
                }
            }
        } message: {
            if let platform = screenState.platformToDelete {
                Text("Are you sure you want to delete \"\(platform.name)\"? This action cannot be undone.")
            }
        }
        .alert("Delete \(screenState.selectedIds.count) Platforms", isPresented: $screenState.showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.bulkDeletePlatforms(ids: Array(screenState.selectedIds))
                    screenState.finishSelection()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(screenState.selectedIds.count) platform(s)? This action cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        AdminPlatformsView()
    }
}
