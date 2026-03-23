import SwiftUI

/// A unified game selector field for use in admin forms.
/// Shows the selected game (or placeholder) and presents GamePickerSheet when tapped.
struct GameSelectorField: View {
    let title: String
    @Binding var selectedGame: GameSummary?
    var excludedGameIds: Set<String> = []
    var filterBaseGamesOnly: Bool = false

    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if let game = selectedGame {
                    HStack(spacing: 8) {
                        if let platform = game.platform {
                            PlatformIcon(slug: platform.slug, size: 14)
                        }
                        Text(game.title)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    Text("Select a game")
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .sheet(isPresented: $showingPicker) {
            if filterBaseGamesOnly {
                BaseGamePickerSheet(
                    excludedGameIds: excludedGameIds
                ) { game in
                    selectedGame = game
                }
            } else {
                GamePickerSheet(
                    title: "Select \(title)",
                    excludedGameIds: excludedGameIds
                ) { game in
                    selectedGame = game
                }
            }
        }
    }
}

/// A variant that works with game ID binding instead of GameSummary
struct GameSelectorFieldById: View {
    let title: String
    @Binding var selectedGameId: String?
    @Binding var selectedGameTitle: String?
    var excludedGameIds: Set<String> = []

    @State private var showingPicker = false

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if let gameTitle = selectedGameTitle {
                    Text(gameTitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Select a game")
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .sheet(isPresented: $showingPicker) {
            GamePickerSheet(
                title: "Select \(title)",
                excludedGameIds: excludedGameIds
            ) { game in
                selectedGameId = game.id
                selectedGameTitle = game.title
            }
        }
    }
}

/// A base game picker sheet that only shows base games (not fangames/ROM hacks)
struct BaseGamePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GameListViewModel()

    let excludedGameIds: Set<String>
    let onSelect: (GameSummary) -> Void

    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?

    init(
        excludedGameIds: Set<String> = [],
        onSelect: @escaping (GameSummary) -> Void
    ) {
        self.excludedGameIds = excludedGameIds
        self.onSelect = onSelect
    }

    var filteredGames: [GameSummary] {
        viewModel.games.filter { game in
            !excludedGameIds.contains(game.id) &&
            (game.type == nil || game.type == .BASE_GAME)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.games.isEmpty {
                    ProgressView("Loading games...")
                } else if !viewModel.isLoading, let error = viewModel.errorMessage, viewModel.games.isEmpty {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            Task {
                                await loadGames()
                            }
                        }
                    }
                } else if filteredGames.isEmpty && !searchText.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView.search(text: searchText)
                } else if filteredGames.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView {
                        Label("No Base Games", systemImage: "gamecontroller")
                    } description: {
                        Text("No base games available")
                    }
                } else if filteredGames.isEmpty && viewModel.isLoading {
                    ProgressView("Searching...")
                } else {
                    List {
                        ForEach(filteredGames) { game in
                            Button {
                                onSelect(game)
                                dismiss()
                            } label: {
                                GameRow(game: game)
                            }
                        }

                        if viewModel.hasNextPage {
                            HStack {
                                Spacer()
                                Button {
                                    Task {
                                        await viewModel.goToNextPage(
                                            search: searchText.isEmpty ? nil : searchText,
                                            platformId: nil,
                                            hasAchievements: nil,
                                            orderBy: "TITLE_ASC"
                                        )
                                    }
                                } label: {
                                    if viewModel.isLoading {
                                        ProgressView()
                                    } else {
                                        Text("Load More")
                                    }
                                }
                                .disabled(viewModel.isLoading)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Base Game")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search base games")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadGames()
            }
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    if !Task.isCancelled {
                        await viewModel.fetchGames(
                            search: newValue.isEmpty ? nil : newValue,
                            platformId: nil,
                            hasAchievements: nil,
                            orderBy: "TITLE_ASC",
                            page: 1
                        )
                    }
                }
            }
        }
    }

    private func loadGames() async {
        await viewModel.fetchGames(
            search: searchText.isEmpty ? nil : searchText,
            platformId: nil,
            hasAchievements: nil,
            orderBy: "TITLE_ASC",
            page: 1
        )
    }
}

#Preview("GameSelectorField - Empty") {
    Form {
        Section("Game Selection") {
            GameSelectorField(
                title: "Game",
                selectedGame: .constant(nil)
            )
        }
    }
}

#Preview("BaseGamePickerSheet") {
    BaseGamePickerSheet { game in
        print("Selected: \(game.title)")
    }
}
