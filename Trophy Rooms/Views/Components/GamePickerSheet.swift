import SwiftUI

/// A reusable game picker sheet that uses the same search and display as the main Games page.
/// Use this anywhere you need to select a game.
struct GamePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GameListViewModel()

    let title: String
    let excludedGameIds: Set<String>
    let onSelect: (GameSummary) -> Void

    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?

    init(
        title: String = "Select Game",
        excludedGameIds: Set<String> = [],
        onSelect: @escaping (GameSummary) -> Void
    ) {
        self.title = title
        self.excludedGameIds = excludedGameIds
        self.onSelect = onSelect
    }

    var filteredGames: [GameSummary] {
        viewModel.games.filter { !excludedGameIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.games.isEmpty {
                    ProgressView("Loading games...")
                } else if let error = viewModel.errorMessage {
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
                } else if filteredGames.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else if filteredGames.isEmpty {
                    ContentUnavailableView {
                        Label("No Games", systemImage: "gamecontroller")
                    } description: {
                        Text("Search for a game to add")
                    }
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

                        // Pagination
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search games")
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
                    try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
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

// MARK: - Game Row Component

struct GameRow: View {
    let game: GameSummary

    var body: some View {
        HStack(spacing: 12) {
            // Cover image
            if let coverUrl = game.coverUrl, let url = URL(string: coverUrl) {
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
                    .overlay {
                        Image(systemName: "gamecontroller")
                            .foregroundStyle(.gray)
                    }
            }

            // Game info
            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let platform = game.platform {
                    HStack(spacing: 4) {
                        PlatformIcon(slug: platform.slug, size: 12)
                        Text(platform.name)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Text("\(game.achievementCount) achievements")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    GamePickerSheet { game in
        print("Selected: \(game.title)")
    }
}
