import SwiftUI

struct AdminAchievementSetsView: View {
    @StateObject private var viewModel = AdminAchievementSetsViewModel()
    @State private var showingCreateSheet = false
    @State private var setToEdit: AdminAchievementSet?
    @State private var setToDelete: AdminAchievementSet?
    @State private var showingDeleteConfirmation = false
    @State private var selectedIds: Set<String> = []
    @State private var isSelecting = false
    @State private var showingBulkDeleteConfirmation = false

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.achievementSets.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            } else {
                ForEach(viewModel.filteredSets) { set in
                    HStack {
                        if isSelecting {
                            Image(systemName: selectedIds.contains(set.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedIds.contains(set.id) ? .blue : .gray)
                                .onTapGesture {
                                    toggleSelection(set.id)
                                }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(set.title)
                                .font(.headline)
                            if let game = set.game {
                                Text(game.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            HStack(spacing: 8) {
                                Text(set.typeEnum.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)

                                Text(set.visibilityEnum.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .cornerRadius(4)

                                if let count = set.achievementCount {
                                    Text("\(count) achievements")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isSelecting {
                            toggleSelection(set.id)
                        } else {
                            setToEdit = set
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        if !isSelecting {
                            Button(role: .destructive) {
                                setToDelete = set
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                setToEdit = set
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search sets or games")
        .navigationTitle("Achievement Sets")
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
                            Label("Add Set", systemImage: "plus")
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
            await viewModel.fetchAchievementSets()
        }
        .task {
            await viewModel.fetchAchievementSets()
            await viewModel.fetchGames()
        }
        .sheet(isPresented: $showingCreateSheet) {
            AdminSetFormSheet(viewModel: viewModel, achievementSet: nil)
        }
        .sheet(item: $setToEdit) { set in
            AdminSetFormSheet(viewModel: viewModel, achievementSet: set)
        }
        .alert("Delete Achievement Set", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                setToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let set = setToDelete {
                    Task {
                        await viewModel.deleteAchievementSet(id: set.id)
                        setToDelete = nil
                    }
                }
            }
        } message: {
            if let set = setToDelete {
                Text("Are you sure you want to delete \"\(set.title)\"? This will also delete all achievements in this set. This action cannot be undone.")
            }
        }
        .alert("Delete \(selectedIds.count) Sets", isPresented: $showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.bulkDeleteAchievementSets(ids: Array(selectedIds))
                    selectedIds.removeAll()
                    isSelecting = false
                }
            }
        } message: {
            Text("Are you sure you want to delete \(selectedIds.count) achievement set(s)? This will also delete all achievements in these sets. This action cannot be undone.")
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
        AdminAchievementSetsView()
    }
}
