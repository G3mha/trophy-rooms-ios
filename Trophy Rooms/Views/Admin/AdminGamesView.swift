import SwiftUI

struct AdminGamesView: View {
    @StateObject private var viewModel = AdminGamesViewModel()
    @State private var showingCreateSheet = false
    @State private var gameToEdit: AdminGame?
    @State private var gameToDelete: AdminGame?
    @State private var showingDeleteConfirmation = false
    @State private var selectedIds: Set<String> = []
    @State private var isSelecting = false
    @State private var showingBulkDeleteConfirmation = false

    var body: some View {
        List {
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
                            if let platform = game.platform {
                                Text(platform.name)
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
                    .onAppear {
                        // Load more when reaching the last few items
                        if game.id == viewModel.filteredGames.last?.id && viewModel.canLoadMore {
                            Task {
                                await viewModel.loadMoreGames()
                            }
                        }
                    }
                }

                // Loading more indicator
                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search games")
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
            await viewModel.fetchGames()
        }
        .task {
            await viewModel.fetchGames()
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
