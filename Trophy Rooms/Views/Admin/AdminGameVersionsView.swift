import SwiftUI

struct AdminGameVersionsView: View {
    @StateObject private var viewModel = AdminGameVersionsViewModel()
    @State private var games: [AdminGame] = []
    @State private var isLoadingGames = false
    @State private var selectedGameId: String?
    @State private var showingCreateSheet = false
    @State private var versionToEdit: GameVersion?
    @State private var versionToDelete: GameVersion?
    @State private var showingDeleteConfirmation = false
    @State private var selectedIds: Set<String> = []
    @State private var isSelecting = false
    @State private var showingBulkDeleteConfirmation = false
    @State private var versionToSetDefault: GameVersion?
    @State private var showingSetDefaultConfirmation = false

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
                    if viewModel.isLoading && viewModel.versions.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    } else if viewModel.versions.isEmpty {
                        Text("No versions found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.versions, id: \.id) { version in
                            HStack(spacing: 12) {
                                if isSelecting {
                                    Image(systemName: selectedIds.contains(version.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedIds.contains(version.id) ? .blue : .gray)
                                        .onTapGesture {
                                            toggleSelection(version.id)
                                        }
                                }

                                if let coverUrl = version.effectiveCoverUrl, let url = URL(string: coverUrl) {
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
                                    HStack {
                                        Text(version.name)
                                            .font(.headline)
                                            .lineLimit(1)
                                        if version.isDefault {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(.yellow)
                                                .font(.caption)
                                        }
                                    }
                                    Text(version.slug ?? "")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let dlc = version.includedDlc, !dlc.isEmpty {
                                        Text("\(dlc.count) DLC included")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                                Text("\(version.achievementSetCount ?? 0) sets")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isSelecting {
                                    toggleSelection(version.id)
                                } else {
                                    versionToEdit = version
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if !isSelecting {
                                    if !version.isDefault {
                                        Button(role: .destructive) {
                                            versionToDelete = version
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }

                                    Button {
                                        versionToEdit = version
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if !isSelecting && !version.isDefault {
                                    Button {
                                        versionToSetDefault = version
                                        showingSetDefaultConfirmation = true
                                    } label: {
                                        Label("Set Default", systemImage: "star")
                                    }
                                    .tint(.yellow)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Versions")
                } footer: {
                    if !viewModel.versions.isEmpty {
                        Text("Swipe left to edit/delete, swipe right to set as default. Default version cannot be deleted.")
                    }
                }
            }
        }
        .navigationTitle("Game Versions")
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
                                Label("Add Version", systemImage: "plus")
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
                let nonDefaultSelected = selectedIds.filter { id in
                    !viewModel.versions.contains { $0.id == id && $0.isDefault }
                }
                if !nonDefaultSelected.isEmpty {
                    Button(role: .destructive) {
                        showingBulkDeleteConfirmation = true
                    } label: {
                        Label("Delete \(nonDefaultSelected.count)", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding()
                    .background(.bar)
                }
            }
        }
        .refreshable {
            if let gameId = selectedGameId {
                await viewModel.fetchVersions(gameId: gameId)
            }
        }
        .task {
            await fetchGames()
        }
        .onChange(of: selectedGameId) { _, newValue in
            if let gameId = newValue {
                Task {
                    await viewModel.fetchVersions(gameId: gameId)
                }
            } else {
                viewModel.versions = []
            }
            selectedIds.removeAll()
            isSelecting = false
        }
        .sheet(isPresented: $showingCreateSheet) {
            if let gameId = selectedGameId {
                AdminGameVersionFormSheet(viewModel: viewModel, gameId: gameId, version: nil)
            }
        }
        .sheet(item: $versionToEdit) { version in
            if let gameId = selectedGameId {
                AdminGameVersionFormSheet(viewModel: viewModel, gameId: gameId, version: version)
            }
        }
        .alert("Delete Version", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                versionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let version = versionToDelete, let gameId = selectedGameId {
                    Task {
                        await viewModel.deleteVersion(id: version.id, gameId: gameId)
                        versionToDelete = nil
                    }
                }
            }
        } message: {
            if let version = versionToDelete {
                Text("Are you sure you want to delete \"\(version.name)\"? This action cannot be undone.")
            }
        }
        .alert("Set Default Version", isPresented: $showingSetDefaultConfirmation) {
            Button("Cancel", role: .cancel) {
                versionToSetDefault = nil
            }
            Button("Set Default") {
                if let version = versionToSetDefault, let gameId = selectedGameId {
                    Task {
                        await viewModel.setDefaultVersion(id: version.id, gameId: gameId)
                        versionToSetDefault = nil
                    }
                }
            }
        } message: {
            if let version = versionToSetDefault {
                Text("Set \"\(version.name)\" as the default version for this game?")
            }
        }
        .alert("Delete Versions", isPresented: $showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let gameId = selectedGameId {
                    let nonDefaultIds = Array(selectedIds.filter { id in
                        !viewModel.versions.contains { $0.id == id && $0.isDefault }
                    })
                    Task {
                        await viewModel.bulkDeleteVersions(ids: nonDefaultIds, gameId: gameId)
                        selectedIds.removeAll()
                        isSelecting = false
                    }
                }
            }
        } message: {
            let nonDefaultCount = selectedIds.filter { id in
                !viewModel.versions.contains { $0.id == id && $0.isDefault }
            }.count
            Text("Are you sure you want to delete \(nonDefaultCount) version(s)? Default versions will be skipped. This action cannot be undone.")
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

#Preview {
    NavigationStack {
        AdminGameVersionsView()
    }
}
