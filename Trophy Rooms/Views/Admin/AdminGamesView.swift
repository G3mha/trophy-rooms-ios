import SwiftUI

struct AdminGamesView: View {
    @StateObject private var viewModel = AdminGamesViewModel()
    @State private var showingCreateSheet = false
    @State private var gameToEdit: AdminGameItem?
    @State private var gameToDelete: AdminGameItem?
    @State private var showingDeleteConfirmation = false
    @State private var selectedIds: Set<String> = []
    @State private var isSelecting = false
    @State private var showingBulkDeleteConfirmation = false

    var body: some View {
        List {
            // Pagination controls
            if viewModel.totalCount > 0 {
                Section {
                    HStack(spacing: 16) {
                        // First page button
                        Button {
                            Task { await viewModel.goToFirstPage() }
                        } label: {
                            Image(systemName: "chevron.backward.2")
                        }
                        .disabled(viewModel.currentPage == 1 || viewModel.isLoading)

                        // Previous button
                        Button {
                            Task { await viewModel.goToPreviousPage() }
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                        .disabled(!viewModel.canGoPrevious)

                        Spacer()

                        // Page info
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Page \(viewModel.currentPage) of \(viewModel.totalPages)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Next button
                        Button {
                            Task { await viewModel.goToNextPage() }
                        } label: {
                            Image(systemName: "chevron.forward")
                        }
                        .disabled(!viewModel.canGoNext)

                        // Last page button
                        Button {
                            Task { await viewModel.goToLastPage() }
                        } label: {
                            Image(systemName: "chevron.forward.2")
                        }
                        .disabled(viewModel.currentPage == viewModel.totalPages || viewModel.isLoading)
                    }
                    .buttonStyle(.borderless)

                    Text("\(viewModel.totalCount) games total")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            if viewModel.isLoading && viewModel.games.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            } else {
                ForEach(viewModel.filteredGames) { game in
                    HStack(spacing: 12) {
                        if isSelecting {
                            Image(systemName: selectedIds.contains(game.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedIds.contains(game.id) ? .blue : .gray)
                                .onTapGesture {
                                    toggleSelection(game.id)
                                }
                        }
                        AsyncImage(url: game.coverUrl.flatMap { URL(string: $0) }) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(game.title)
                                .font(.headline)
                                .lineLimit(1)
                            if let platformName = game.platformName {
                                Text(platformName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text("\(game.achievementSetCount) sets")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isSelecting {
                            toggleSelection(game.id)
                        } else {
                            gameToEdit = game
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        if !isSelecting {
                            Button(role: .destructive) {
                                gameToDelete = game
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                gameToEdit = game
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
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
        .navigationTitle("Games")
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
                            Label("Add Game", systemImage: "plus")
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
            await viewModel.fetchGames(page: viewModel.currentPage)
        }
        .task {
            await viewModel.fetchGames(page: 1)
            await viewModel.fetchPlatforms()
        }
        .sheet(isPresented: $showingCreateSheet) {
            AdminGameFormSheet(viewModel: viewModel, game: nil)
        }
        .sheet(item: $gameToEdit) { game in
            AdminGameFormSheet(viewModel: viewModel, game: game)
        }
        .alert("Delete Game", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                gameToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let game = gameToDelete {
                    Task {
                        await viewModel.deleteGame(id: game.id)
                        gameToDelete = nil
                    }
                }
            }
        } message: {
            if let game = gameToDelete {
                Text("Are you sure you want to delete \"\(game.title)\"? This will also delete all achievement sets and achievements. This action cannot be undone.")
            }
        }
        .alert("Delete \(selectedIds.count) Games", isPresented: $showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.bulkDeleteGames(ids: Array(selectedIds))
                    selectedIds.removeAll()
                    isSelecting = false
                }
            }
        } message: {
            Text("Are you sure you want to delete \(selectedIds.count) game(s)? This will also delete all related achievement sets and achievements. This action cannot be undone.")
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
        AdminGamesView()
    }
}
