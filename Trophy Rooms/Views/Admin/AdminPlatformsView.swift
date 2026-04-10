import SwiftUI

struct AdminPlatformsView: View {
    @StateObject private var viewModel = AdminPlatformsViewModel()
    @State private var showingCreateSheet = false
    @State private var platformToEdit: AdminPlatform?
    @State private var platformToDelete: AdminPlatform?
    @State private var showingDeleteConfirmation = false
    @State private var selectedIds: Set<String> = []
    @State private var isSelecting = false
    @State private var showingBulkDeleteConfirmation = false

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.platforms.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            } else {
                ForEach(viewModel.platforms) { platform in
                    HStack {
                        if isSelecting {
                            Image(systemName: selectedIds.contains(platform.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedIds.contains(platform.id) ? .blue : .gray)
                                .onTapGesture {
                                    toggleSelection(platform.id)
                                }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(platform.name)
                                .font(.headline)
                            Text(platform.slug)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isSelecting {
                            toggleSelection(platform.id)
                        } else {
                            platformToEdit = platform
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        if !isSelecting {
                            Button(role: .destructive) {
                                platformToDelete = platform
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                platformToEdit = platform
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("Platforms")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isSelecting {
                    Button("Done") {
                        isSelecting = false
                        selectedIds.removeAll()
                    }
                } else {
                    Menu {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            Label("Add Platform", systemImage: "plus")
                        }

                        Button {
                            isSelecting = true
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
            if isSelecting && !selectedIds.isEmpty {
                Button(role: .destructive) {
                    showingBulkDeleteConfirmation = true
                } label: {
                    Label("Delete \(selectedIds.count)", systemImage: "trash")
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
        .sheet(isPresented: $showingCreateSheet) {
            AdminPlatformFormSheet(viewModel: viewModel, platform: nil)
        }
        .sheet(item: $platformToEdit) { platform in
            AdminPlatformFormSheet(viewModel: viewModel, platform: platform)
        }
        .alert("Delete Platform", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                platformToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let platform = platformToDelete {
                    Task {
                        _ = await viewModel.deletePlatform(id: platform.id)
                        platformToDelete = nil
                    }
                }
            }
        } message: {
            if let platform = platformToDelete {
                Text("Are you sure you want to delete \"\(platform.name)\"? This action cannot be undone.")
            }
        }
        .alert("Delete \(selectedIds.count) Platforms", isPresented: $showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.bulkDeletePlatforms(ids: Array(selectedIds))
                    selectedIds.removeAll()
                    isSelecting = false
                }
            }
        } message: {
            Text("Are you sure you want to delete \(selectedIds.count) platform(s)? This action cannot be undone.")
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
}

#Preview {
    NavigationStack {
        AdminPlatformsView()
    }
}
