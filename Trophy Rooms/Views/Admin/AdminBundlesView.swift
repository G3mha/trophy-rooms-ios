import SwiftUI

struct AdminBundlesView: View {
    @StateObject private var viewModel = AdminBundlesViewModel()
    @StateObject private var screenState = AdminBundlesScreenState()

    var body: some View {
        List {
            AdminBundlesFilterSection(selectedType: $screenState.selectedType)
            AdminBundlesListSection(viewModel: viewModel, screenState: screenState)
        }
        .navigationTitle("Bundles")
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
                            Label("Add Bundle", systemImage: "plus")
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
            await viewModel.fetchBundles(type: screenState.selectedType)
        }
        .task {
            await viewModel.fetchBundles(type: screenState.selectedType)
        }
        .onChange(of: screenState.selectedType) { _, newValue in
            Task {
                await viewModel.fetchBundles(type: newValue)
            }
            screenState.finishSelection()
        }
        .sheet(isPresented: $screenState.showingCreateSheet) {
            AdminBundleFormSheet(viewModel: viewModel, bundle: nil)
        }
        .sheet(item: $screenState.bundleToEdit) { bundle in
            AdminBundleFormSheet(viewModel: viewModel, bundle: bundle)
        }
        .sheet(item: $screenState.bundleToManageContents) { bundle in
            AdminBundleContentsSheet(viewModel: viewModel, bundleId: bundle.id)
        }
        .alert("Delete Bundle", isPresented: $screenState.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                screenState.bundleToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let bundle = screenState.bundleToDelete {
                    Task {
                        _ = await viewModel.deleteBundle(id: bundle.id)
                        screenState.bundleToDelete = nil
                    }
                }
            }
        } message: {
            if let bundle = screenState.bundleToDelete {
                Text("Are you sure you want to delete \"\(bundle.name)\"? This action cannot be undone.")
            }
        }
        .alert("Delete Bundles", isPresented: $screenState.showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.bulkDeleteBundles(ids: Array(screenState.selectedIds))
                    screenState.finishSelection()
                }
            }
        } message: {
            Text("Are you sure you want to delete \(screenState.selectedIds.count) bundle(s)? This action cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        AdminBundlesView()
    }
}
