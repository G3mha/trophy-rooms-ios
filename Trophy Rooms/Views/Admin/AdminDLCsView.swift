import SwiftUI

struct AdminDLCsView: View {
    @StateObject private var viewModel = AdminDLCsViewModel()
    @State private var games: [AdminGame] = []
    @State private var isLoadingGames = false
    @State private var selectedGameId: String?
    @State private var showingCreateSheet = false
    @State private var dlcToEdit: DLC?
    @State private var dlcToDelete: DLC?
    @State private var showingDeleteConfirmation = false
    @State private var selectedIds: Set<String> = []
    @State private var isSelecting = false
    @State private var showingBulkDeleteConfirmation = false

    var body: some View {
        List {
            Section {
                Picker("Game", selection: $selectedGameId) {
                    Text("Select a game").tag(nil as String?)
                    ForEach(games, id: \.id) { game in
                        HStack {
                            Text(game.title)
                            if let platform = game.platform {
                                Text("(\(platform.name))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(game.id as String?)
                    }
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("Select Game")
            }

            if selectedGameId != nil {
                Section {
                    if viewModel.isLoading && viewModel.dlcs.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    } else if viewModel.dlcs.isEmpty {
                        Text("No DLCs found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.dlcs, id: \.id) { dlc in
                            HStack(spacing: 12) {
                                if isSelecting {
                                    Image(systemName: selectedIds.contains(dlc.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedIds.contains(dlc.id) ? .blue : .gray)
                                        .onTapGesture {
                                            toggleSelection(dlc.id)
                                        }
                                }

                                if let coverUrl = dlc.effectiveCoverUrl, let url = URL(string: coverUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.gray.opacity(0.3)
                                    }
                                    .frame(width: 50, height: 50)
                                    .cornerRadius(8)
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 50, height: 50)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dlc.name)
                                        .font(.headline)
                                        .lineLimit(1)
                                    HStack(spacing: 8) {
                                        Text(dlc.slug)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        DLCTypeBadge(type: dlc.type)
                                    }
                                    if let price = dlc.price {
                                        Text(String(format: "$%.2f", price))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                                if let count = dlc.achievementSetCount, count > 0 {
                                    Text("\(count) sets")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelecting {
                                    toggleSelection(dlc.id)
                                } else {
                                    dlcToEdit = dlc
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if !isSelecting {
                                    Button(role: .destructive) {
                                        dlcToDelete = dlc
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    Button {
                                        dlcToEdit = dlc
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("DLCs & Expansions")
                } footer: {
                    if !viewModel.dlcs.isEmpty {
                        Text("Swipe left to edit or delete.")
                    }
                }
            }
        }
        .navigationTitle("DLCs & Expansions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if selectedGameId != nil {
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
                                Label("Add DLC", systemImage: "plus")
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
            if let gameId = selectedGameId {
                await viewModel.fetchDLCs(gameId: gameId)
            }
        }
        .task {
            await fetchGames()
        }
        .onChange(of: selectedGameId) { _, newValue in
            if let gameId = newValue {
                Task {
                    await viewModel.fetchDLCs(gameId: gameId)
                }
            } else {
                viewModel.dlcs = []
            }
            selectedIds.removeAll()
            isSelecting = false
        }
        .sheet(isPresented: $showingCreateSheet) {
            if let gameId = selectedGameId {
                AdminDLCFormSheet(viewModel: viewModel, gameId: gameId, dlc: nil)
            }
        }
        .sheet(item: $dlcToEdit) { dlc in
            if let gameId = selectedGameId {
                AdminDLCFormSheet(viewModel: viewModel, gameId: gameId, dlc: dlc)
            }
        }
        .alert("Delete DLC", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                dlcToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let dlc = dlcToDelete, let gameId = selectedGameId {
                    Task {
                        await viewModel.deleteDLC(id: dlc.id, gameId: gameId)
                        dlcToDelete = nil
                    }
                }
            }
        } message: {
            if let dlc = dlcToDelete {
                Text("Are you sure you want to delete \"\(dlc.name)\"? This action cannot be undone.")
            }
        }
        .alert("Delete DLCs", isPresented: $showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let gameId = selectedGameId {
                    Task {
                        await viewModel.bulkDeleteDLCs(ids: Array(selectedIds), gameId: gameId)
                        selectedIds.removeAll()
                        isSelecting = false
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \(selectedIds.count) DLC(s)? This action cannot be undone.")
        }
    }

    private func fetchGames() async {
        isLoadingGames = true
        let query = """
        query GetGames {
            games(first: 500) {
                edges {
                    node {
                        id
                        title
                        platform {
                            id
                            name
                            slug
                        }
                    }
                }
            }
        }
        """

        do {
            let response: AdminGamesResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.games = response.games.edges.map { $0.node }
                self.isLoadingGames = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoadingGames = false
            }
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

// DLCTypeBadge is defined in Components/DLCCard.swift

#Preview {
    NavigationStack {
        AdminDLCsView()
    }
}
