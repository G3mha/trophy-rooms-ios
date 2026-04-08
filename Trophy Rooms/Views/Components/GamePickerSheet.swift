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

    /// Groups games by title, combining platforms for the same game
    var groupedGames: [GamePickerGroup] {
        let grouped = Dictionary(grouping: filteredGames) { $0.title }
        return grouped.map { title, games in
            GamePickerGroup(
                title: title,
                coverUrl: games.first?.coverUrl,
                games: games.sorted { ($0.platform?.name ?? "") < ($1.platform?.name ?? "") },
                totalAchievements: games.reduce(0) { $0 + $1.achievementCount }
            )
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
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
                        Label("No Games", systemImage: "gamecontroller")
                    } description: {
                        Text("Search for a game to add")
                    }
                } else if filteredGames.isEmpty && viewModel.isLoading {
                    ProgressView("Searching...")
                } else {
                    List {
                        ForEach(groupedGames) { group in
                            GroupedGameRow(group: group, onSelect: { game in
                                onSelect(game)
                                dismiss()
                            })
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

// MARK: - Game Picker Group

struct GamePickerGroup: Identifiable {
    let title: String
    let coverUrl: String?
    let games: [GameSummary]
    let totalAchievements: Int

    var id: String { title }
    var isSingleGame: Bool { games.count == 1 }
    var platforms: [Platform] {
        games.compactMap { $0.platform }
    }
}

// MARK: - Grouped Game Row

struct GroupedGameRow: View {
    let group: GamePickerGroup
    let onSelect: (GameSummary) -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button {
                if group.isSingleGame {
                    onSelect(group.games[0])
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    // Cover image
                    if let coverUrl = group.coverUrl, let url = URL(string: coverUrl) {
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
                        Text(group.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        // Platform icons row
                        HStack(spacing: 4) {
                            ForEach(group.platforms.prefix(6), id: \.id) { platform in
                                PlatformIcon(slug: platform.slug, size: 14)
                            }
                            if group.platforms.count > 6 {
                                Text("+\(group.platforms.count - 6)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text("\(group.totalAchievements) achievements")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    if !group.isSingleGame {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded platform list
            if isExpanded && !group.isSingleGame {
                VStack(spacing: 0) {
                    ForEach(group.games, id: \.id) { game in
                        Button {
                            onSelect(game)
                        } label: {
                            HStack(spacing: 12) {
                                Spacer()
                                    .frame(width: 50)

                                if let platform = game.platform {
                                    PlatformIcon(slug: platform.slug, size: 16)
                                    Text(platform.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                }

                                Spacer()

                                Text("\(game.achievementCount) sets")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if game.id != group.games.last?.id {
                            Divider()
                                .padding(.leading, 62)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

#Preview {
    GamePickerSheet { game in
        print("Selected: \(game.title)")
    }
}
