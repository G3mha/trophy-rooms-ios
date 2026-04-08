import SwiftUI
import ClerkKit

struct GameListView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = GameListViewModel()
    @State private var showAuth = false
    @State private var searchText = ""
    @State private var selectedPlatformId = ""
    @State private var achievementFilter: AchievementFilter = .all
    @State private var sortOption: SortOption = .titleAsc
    @State private var minAchievementCount = 0
    @State private var gameTypeFilter: GameTypeFilter = .all
    @State private var selectedPageSize = 25

    var filteredGameGroups: [GameGroup] {
        viewModel.gameGroups.filter { group in
            group.totalAchievementCount >= minAchievementCount
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.games.isEmpty {
                ProgressView("Loading games...")
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else {
                List {
                    Section {
                        Picker("Platform", selection: $selectedPlatformId) {
                            Text("All Platforms").tag("")
                            ForEach(viewModel.platforms) { platform in
                                Text(platform.name).tag(platform.id)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Achievements", selection: $achievementFilter) {
                            ForEach(AchievementFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Sort", selection: $sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Min Achievements", selection: $minAchievementCount) {
                            ForEach(MinAchievementOption.allCases) { option in
                                Text(option.title).tag(option.value)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Type", selection: $gameTypeFilter) {
                            ForEach(GameTypeFilter.allCases) { filter in
                                Text(filter.title).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Results", selection: $selectedPageSize) {
                            ForEach(PageSizeOption.allCases) { option in
                                Text(option.title).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Section {
                        ForEach(filteredGameGroups) { group in
                            if group.isSingleGame, let game = group.games.first {
                                // Single game - navigate directly to game detail
                                NavigationLink(destination: GameDetailView(gameId: game.id)) {
                                    GameRowView(game: game)
                                }
                            } else {
                                // Multiple platforms - navigate to game family view
                                NavigationLink(destination: GameFamilyView(title: group.title)) {
                                    GroupedGameRowView(group: group)
                                }
                            }
                        }
                    } header: {
                        if viewModel.totalCount > 0 {
                            Text("\(filteredGameGroups.count) titles (\(viewModel.totalCount) versions)")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .safeAreaInset(edge: .bottom) {
                    if viewModel.totalPages > 1 {
                        PaginationControls(
                            currentPage: viewModel.currentPage,
                            totalPages: viewModel.totalPages,
                            isLoading: viewModel.isLoading,
                            onPrevious: {
                                Task {
                                    await viewModel.goToPreviousPage(
                                        search: searchText,
                                        platformId: selectedPlatformId,
                                        hasAchievements: achievementFilter.boolValue,
                                        orderBy: sortOption.graphqlValue,
                                        type: gameTypeFilter.graphqlValue
                                    )
                                }
                            },
                            onNext: {
                                Task {
                                    await viewModel.goToNextPage(
                                        search: searchText,
                                        platformId: selectedPlatformId,
                                        hasAchievements: achievementFilter.boolValue,
                                        orderBy: sortOption.graphqlValue,
                                        type: gameTypeFilter.graphqlValue
                                    )
                                }
                            },
                            onGoToPage: { page in
                                Task {
                                    await viewModel.goToPage(
                                        page,
                                        search: searchText,
                                        platformId: selectedPlatformId,
                                        hasAchievements: achievementFilter.boolValue,
                                        orderBy: sortOption.graphqlValue,
                                        type: gameTypeFilter.graphqlValue
                                    )
                                }
                            }
                        )
                    }
                }
            }
        }
        .navigationBar(title: "Games", showAuth: $showAuth)
        .sheet(isPresented: $showAuth) {
            AuthView()
        }
        .searchable(text: $searchText)
        .onChange(of: searchText) {
            Task {
                await viewModel.fetchGames(
                    search: searchText,
                    platformId: selectedPlatformId,
                    hasAchievements: achievementFilter.boolValue,
                    orderBy: sortOption.graphqlValue,
                    type: gameTypeFilter.graphqlValue,
                    page: 1
                )
            }
        }
        .onChange(of: selectedPlatformId) {
            Task {
                await viewModel.fetchGames(
                    search: searchText,
                    platformId: selectedPlatformId,
                    hasAchievements: achievementFilter.boolValue,
                    orderBy: sortOption.graphqlValue,
                    type: gameTypeFilter.graphqlValue,
                    page: 1
                )
            }
        }
        .onChange(of: achievementFilter) {
            Task {
                await viewModel.fetchGames(
                    search: searchText,
                    platformId: selectedPlatformId,
                    hasAchievements: achievementFilter.boolValue,
                    orderBy: sortOption.graphqlValue,
                    type: gameTypeFilter.graphqlValue,
                    page: 1
                )
            }
        }
        .onChange(of: sortOption) {
            Task {
                await viewModel.fetchGames(
                    search: searchText,
                    platformId: selectedPlatformId,
                    hasAchievements: achievementFilter.boolValue,
                    orderBy: sortOption.graphqlValue,
                    type: gameTypeFilter.graphqlValue,
                    page: 1
                )
            }
        }
        .onChange(of: gameTypeFilter) {
            Task {
                await viewModel.fetchGames(
                    search: searchText,
                    platformId: selectedPlatformId,
                    hasAchievements: achievementFilter.boolValue,
                    orderBy: sortOption.graphqlValue,
                    type: gameTypeFilter.graphqlValue,
                    page: 1
                )
            }
        }
        .onChange(of: selectedPageSize) {
            Task {
                await viewModel.setPageSize(
                    selectedPageSize,
                    search: searchText,
                    platformId: selectedPlatformId,
                    hasAchievements: achievementFilter.boolValue,
                    orderBy: sortOption.graphqlValue,
                    type: gameTypeFilter.graphqlValue
                )
            }
        }
        .task {
            await viewModel.fetchPlatforms()
            await viewModel.fetchGames(
                search: searchText,
                platformId: selectedPlatformId,
                hasAchievements: achievementFilter.boolValue,
                orderBy: sortOption.graphqlValue,
                type: gameTypeFilter.graphqlValue,
                page: 1
            )
        }
    }
}

// MARK: - Pagination Controls

private struct PaginationControls: View {
    let currentPage: Int
    let totalPages: Int
    let isLoading: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onGoToPage: (Int) -> Void

    @State private var showPagePicker = false

    var body: some View {
        HStack(spacing: 16) {
            // Previous button
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .disabled(currentPage <= 1 || isLoading)
            .opacity(currentPage <= 1 ? 0.3 : 1)

            Spacer()

            // Page indicator - tappable to show page picker
            Button {
                showPagePicker = true
            } label: {
                HStack(spacing: 4) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Page \(currentPage) of \(totalPages)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .foregroundStyle(.primary)
            }
            .disabled(isLoading)

            Spacer()

            // Next button
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .disabled(currentPage >= totalPages || isLoading)
            .opacity(currentPage >= totalPages ? 0.3 : 1)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
        .sheet(isPresented: $showPagePicker) {
            PagePickerSheet(
                currentPage: currentPage,
                totalPages: totalPages,
                onSelect: { page in
                    showPagePicker = false
                    onGoToPage(page)
                }
            )
            .presentationDetents([.medium])
        }
    }
}

private struct PagePickerSheet: View {
    let currentPage: Int
    let totalPages: Int
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPage: Int

    init(currentPage: Int, totalPages: Int, onSelect: @escaping (Int) -> Void) {
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.onSelect = onSelect
        self._selectedPage = State(initialValue: currentPage)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Go to Page")
                    .font(.headline)

                Picker("Page", selection: $selectedPage) {
                    ForEach(1...totalPages, id: \.self) { page in
                        Text("\(page)").tag(page)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)

                Button {
                    onSelect(selectedPage)
                } label: {
                    Text("Go to Page \(selectedPage)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

enum AchievementFilter: String, CaseIterable, Identifiable {
    case all
    case withAchievements
    case withoutAchievements

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .withAchievements:
            return "With Achievements"
        case .withoutAchievements:
            return "Without Achievements"
        }
    }

    var boolValue: Bool? {
        switch self {
        case .all:
            return nil
        case .withAchievements:
            return true
        case .withoutAchievements:
            return false
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case titleAsc
    case titleDesc
    case newest
    case oldest
    case mostAchievements
    case mostTrophies

    var id: String { rawValue }

    var title: String {
        switch self {
        case .titleAsc:
            return "Title (A → Z)"
        case .titleDesc:
            return "Title (Z → A)"
        case .newest:
            return "Newest"
        case .oldest:
            return "Oldest"
        case .mostAchievements:
            return "Most Achievements"
        case .mostTrophies:
            return "Most Trophies"
        }
    }

    var graphqlValue: String {
        switch self {
        case .titleAsc:
            return "TITLE_ASC"
        case .titleDesc:
            return "TITLE_DESC"
        case .newest:
            return "CREATED_AT_DESC"
        case .oldest:
            return "CREATED_AT_ASC"
        case .mostAchievements:
            return "ACHIEVEMENT_COUNT_DESC"
        case .mostTrophies:
            return "TROPHY_COUNT_DESC"
        }
    }
}

enum MinAchievementOption: Int, CaseIterable, Identifiable {
    case any = 0
    case five = 5
    case ten = 10
    case twentyFive = 25

    var id: Int { rawValue }

    var value: Int { rawValue }

    var title: String {
        switch self {
        case .any:
            return "Any"
        case .five:
            return "5+"
        case .ten:
            return "10+"
        case .twentyFive:
            return "25+"
        }
    }
}

enum GameTypeFilter: String, CaseIterable, Identifiable {
    case all
    case baseGames
    case fangames
    case romHacks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Types"
        case .baseGames:
            return "Base Games"
        case .fangames:
            return "Fangames"
        case .romHacks:
            return "ROM Hacks"
        }
    }

    var graphqlValue: String? {
        switch self {
        case .all:
            return nil
        case .baseGames:
            return "BASE_GAME"
        case .fangames:
            return "FANGAME"
        case .romHacks:
            return "ROM_HACK"
        }
    }
}

// MARK: - Game Row View (Single Platform)

private struct GameRowView: View {
    let game: GameSummary

    var body: some View {
        HStack {
            if let coverUrl = game.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(game.title)
                        .font(.headline)
                    if let type = game.type, type != .BASE_GAME {
                        Text(type.shortName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(type == .FANGAME ? Color.purple.opacity(0.2) : Color.orange.opacity(0.2))
                            .foregroundColor(type == .FANGAME ? .purple : .orange)
                            .clipShape(Capsule())
                    }
                }
                if let platform = game.platform {
                    HStack(spacing: 4) {
                        PlatformIcon(slug: platform.slug, size: 12)
                        Text(platform.name)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                } else {
                    Text("Unknown Platform")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text("\(game.achievementCount) achievements")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Grouped Game Row View (Multiple Platforms)

private struct GroupedGameRowView: View {
    let group: GameGroup

    private let maxPlatformIcons = 4

    var body: some View {
        HStack {
            if let coverUrl = group.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.title)
                    .font(.headline)

                // Platform icons row
                HStack(spacing: 4) {
                    ForEach(group.platforms.prefix(maxPlatformIcons), id: \.id) { platform in
                        PlatformIcon(slug: platform.slug, size: 14)
                    }
                    if group.platforms.count > maxPlatformIcons {
                        Text("+\(group.platforms.count - maxPlatformIcons)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Text("\(group.totalAchievementCount) achievements")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
