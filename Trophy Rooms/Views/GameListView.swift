import SwiftUI
import ClerkKit
import ClerkKitUI

struct GameListView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = GameListViewModel()
    @State private var showAuth = false
    @State private var searchText = ""
    @State private var selectedPlatformId = ""
    @State private var achievementFilter: AchievementFilter = .all
    @State private var sortOption: SortOption = .titleAsc
    @State private var minAchievementCount = 0

    var filteredGames: [GameSummary] {
        viewModel.games.filter { game in
            game.achievementCount >= minAchievementCount
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
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
                    }

                    Section {
                        ForEach(filteredGames) { game in
                            NavigationLink(destination: GameDetailView(gameId: game.id)) {
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
                                        Text(game.title)
                                            .font(.headline)
                                        Text(game.platform?.name ?? "Unknown Platform")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("\(game.achievementCount) achievements")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Trophy Rooms")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if clerk.user != nil {
                    UserButton()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                } else {
                    Button("Sign In") {
                        showAuth = true
                    }
                }
            }
        }
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
                    orderBy: sortOption.graphqlValue
                )
            }
        }
        .onChange(of: selectedPlatformId) {
            Task {
                await viewModel.fetchGames(
                    search: searchText,
                    platformId: selectedPlatformId,
                    hasAchievements: achievementFilter.boolValue,
                    orderBy: sortOption.graphqlValue
                )
            }
        }
        .onChange(of: achievementFilter) {
            Task {
                await viewModel.fetchGames(
                    search: searchText,
                    platformId: selectedPlatformId,
                    hasAchievements: achievementFilter.boolValue,
                    orderBy: sortOption.graphqlValue
                )
            }
        }
        .onChange(of: sortOption) {
            Task {
                await viewModel.fetchGames(
                    search: searchText,
                    platformId: selectedPlatformId,
                    hasAchievements: achievementFilter.boolValue,
                    orderBy: sortOption.graphqlValue
                )
            }
        }
        .task {
            await viewModel.fetchPlatforms()
            await viewModel.fetchGames(
                search: searchText,
                platformId: selectedPlatformId,
                hasAchievements: achievementFilter.boolValue,
                orderBy: sortOption.graphqlValue
            )
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
