import SwiftUI
import ClerkKit

private enum HomeTab: Int, Hashable {
    case games = 0
    case leaderboard = 1
    case activity = 2
}

struct HomeView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var gameListViewModel = GameListViewModel()
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()
    @StateObject private var globalSearchViewModel = GlobalSearchViewModel()
    @State private var showAuth = false
    @State private var searchText = ""
    @State private var selectedPlatformId = ""
    @State private var achievementFilter: AchievementFilter = .all
    @State private var sortOption: SortOption = .titleAsc
    @State private var minAchievementCount = 0
    @State private var gameTypeFilter: GameTypeFilter = .all
    @State private var selectedPageSize = 25
    @State private var showFilters = false
    @State private var selectedTab: HomeTab = .games

    private let homeTabs: [InlineTab<HomeTab>] = [
        InlineTab(title: "Games", icon: "gamecontroller.fill", value: .games),
        InlineTab(title: "Leaderboard", icon: "chart.bar.fill", value: .leaderboard),
        InlineTab(title: "Activity", icon: "clock.fill", value: .activity)
    ]

    var activeFilterCount: Int {
        var count = 0
        if !selectedPlatformId.isEmpty { count += 1 }
        if achievementFilter != .all { count += 1 }
        if sortOption != .titleAsc { count += 1 }
        if minAchievementCount > 0 { count += 1 }
        if gameTypeFilter != .all { count += 1 }
        if selectedPageSize != 25 { count += 1 }
        return count
    }

    var filteredGameGroups: [GameGroup] {
        gameListViewModel.gameGroups.filter { group in
            group.totalAchievementCount >= minAchievementCount
        }
    }

    var isSearching: Bool {
        searchText.trimmingCharacters(in: .whitespaces).count >= 2
    }

    // scrollPosition(id:) needs an optional binding; it reports nil mid-swipe,
    // which must not clear the selected tab.
    private var pagedTabSelection: Binding<HomeTab?> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if let newTab {
                    selectedTab = newTab
                }
            }
        )
    }

    var body: some View {
        Group {
            if isSearching {
                // MARK: - Global Search Results
                GlobalSearchResultsView(viewModel: globalSearchViewModel)
            } else {
                // MARK: - Tabbed Content
                VStack(spacing: 0) {
                    // Tab picker
                    InlineTabPicker(selectedTab: $selectedTab, tabs: homeTabs)

                    // Tab content — a paging ScrollView instead of TabView(.page):
                    // the UIKit-backed pager re-applies the window's bottom safe area
                    // inside each page, keeping content from reaching the screen bottom.
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 0) {
                            // MARK: - Games Tab
                            GamesGridTab(
                                viewModel: gameListViewModel,
                                filteredGameGroups: filteredGameGroups,
                                searchText: searchText,
                                selectedPlatformId: selectedPlatformId,
                                achievementFilter: achievementFilter,
                                sortOption: sortOption,
                                gameTypeFilter: gameTypeFilter
                            )
                            .containerRelativeFrame([.horizontal, .vertical])
                            .id(HomeTab.games)

                            // MARK: - Leaderboard Tab
                            LeaderboardTab(viewModel: leaderboardViewModel)
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(HomeTab.leaderboard)

                            // MARK: - Activity Tab
                            ActivityTab(viewModel: activityViewModel)
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(HomeTab.activity)
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollIndicators(.hidden)
                    .scrollPosition(id: pagedTabSelection)
                }
                // Extend under the floating tab bar so page content can scroll beneath it.
                .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .navigationBar(title: "Home", showAuth: $showAuth)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if selectedTab == .games {
                    Button {
                        showFilters = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            if activeFilterCount > 0 {
                                Text("\(activeFilterCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAuth) {
            AuthView()
        }
        .sheet(isPresented: $showFilters) {
            GameFiltersSheet(
                platforms: gameListViewModel.platforms,
                selectedPlatformId: $selectedPlatformId,
                achievementFilter: $achievementFilter,
                sortOption: $sortOption,
                minAchievementCount: $minAchievementCount,
                gameTypeFilter: $gameTypeFilter,
                selectedPageSize: $selectedPageSize
            )
        }
        .onChange(of: searchText) {
            Task {
                if isSearching {
                    await globalSearchViewModel.search(query: searchText)
                } else {
                    globalSearchViewModel.clearResults()
                }
            }
        }
        .onChange(of: selectedPlatformId) {
            Task {
                await gameListViewModel.fetchGames(
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
                await gameListViewModel.fetchGames(
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
                await gameListViewModel.fetchGames(
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
                await gameListViewModel.fetchGames(
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
                await gameListViewModel.setPageSize(
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
            await gameListViewModel.fetchPlatforms()
            await gameListViewModel.fetchGames(
                search: searchText,
                platformId: selectedPlatformId,
                hasAchievements: achievementFilter.boolValue,
                orderBy: sortOption.graphqlValue,
                type: gameTypeFilter.graphqlValue,
                page: 1
            )
            await leaderboardViewModel.fetchLeaderboard()
            await activityViewModel.fetchActivity()
        }
    }
}

// MARK: - Games Grid Tab

private struct GamesGridTab: View {
    @ObservedObject var viewModel: GameListViewModel
    let filteredGameGroups: [GameGroup]
    let searchText: String
    let selectedPlatformId: String
    let achievementFilter: AchievementFilter
    let sortOption: SortOption
    let gameTypeFilter: GameTypeFilter

    @Namespace private var zoomNamespace

    private let columns = GameCoverGridLayout.columns()

    var body: some View {
        if viewModel.isLoading && viewModel.games.isEmpty {
            VStack {
                Spacer()
                ProgressView("Loading games...")
                Spacer()
            }
        } else if let error = viewModel.errorMessage {
            VStack {
                Spacer()
                Text("Error: \(error)")
                    .foregroundColor(.red)
                Spacer()
            }
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    // Game count header
                    if viewModel.totalCount > 0 {
                        HStack {
                            Text("\(filteredGameGroups.count) titles")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    // Cover grid using reusable components
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredGameGroups) { group in
                            if group.isSingleGame, let game = group.games.first {
                                NavigationLink(
                                    destination: GameDetailView(gameId: game.id)
                                        .navigationTransition(.zoom(sourceID: group.id, in: zoomNamespace))
                                ) {
                                    GameCoverWithContextMenu(
                                        gameId: game.id,
                                        gameTitle: game.title,
                                        coverUrl: game.coverUrl,
                                        platformId: game.platform?.id
                                    ) {
                                        EmptyView()
                                    }
                                }
                                .matchedTransitionSource(id: group.id, in: zoomNamespace)
                            } else {
                                NavigationLink(
                                    destination: GameFamilyView(title: group.title)
                                        .navigationTransition(.zoom(sourceID: group.id, in: zoomNamespace))
                                ) {
                                    GameCoverCell(coverUrl: group.coverUrl, title: group.title) {
                                        GroupIndicatorOverlay()
                                    }
                                }
                                .matchedTransitionSource(id: group.id, in: zoomNamespace)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    // Pagination
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
                        .padding(.bottom)
                    }
                }
            }
            .contentMargins(.bottom, 100, for: .scrollContent)
        }
    }
}

// MARK: - Leaderboard Tab

private struct LeaderboardTab: View {
    @ObservedObject var viewModel: LeaderboardViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LeaderboardSectionContent(viewModel: viewModel)
            }
            .padding()
        }
        .contentMargins(.bottom, 100, for: .scrollContent)
    }
}

// MARK: - Activity Tab

private struct ActivityTab: View {
    @ObservedObject var viewModel: ActivityViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ActivitySectionContent(viewModel: viewModel)
            }
            .padding()
        }
        .contentMargins(.bottom, 100, for: .scrollContent)
    }
}

// MARK: - Leaderboard Section Content

private struct LeaderboardSectionContent: View {
    @ObservedObject var viewModel: LeaderboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Leaderboard type picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LeaderboardType.allCases) { type in
                        LeaderboardTypeChip(
                            type: type,
                            isSelected: viewModel.selectedType == type
                        ) {
                            viewModel.selectedType = type
                            Task {
                                await viewModel.fetchLeaderboard()
                            }
                        }
                    }
                }
            }

            // Leaderboard content
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if viewModel.selectedType == .fastest {
                if viewModel.fastestEntries.isEmpty {
                    LeaderboardEmptyState()
                } else {
                    FastestCompletionsPreview(entries: Array(viewModel.fastestEntries.prefix(5)))
                }
            } else {
                if viewModel.entries.isEmpty {
                    LeaderboardEmptyState()
                } else {
                    LeaderboardPreview(entries: Array(viewModel.entries.prefix(5)), type: viewModel.selectedType)
                }
            }
        }
    }
}

private struct LeaderboardEmptyState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title)
                .foregroundColor(.secondary)
            Text("No leaderboard data yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

private struct LeaderboardTypeChip: View {
    let type: LeaderboardType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

private struct LeaderboardPreview: View {
    let entries: [LeaderboardEntry]
    let type: LeaderboardType

    var body: some View {
        VStack(spacing: 0) {
            ForEach(entries) { entry in
                NavigationLink(destination: UserProfileView(userId: entry.userId, userName: entry.userName)) {
                    LeaderboardRow(entry: entry, type: type)
                }
                if entry.id != entries.last?.id {
                    Divider()
                        .padding(.leading, 60)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let type: LeaderboardType

    var valueLabel: String {
        switch type {
        case .trophies: return "\(entry.value)"
        case .achievements: return "\(entry.value)"
        case .points: return "\(entry.value) pts"
        case .games: return "\(entry.value)"
        case .fastest: return ""
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RankBadge(rank: entry.rank)

            Text(entry.userName ?? entry.userEmail)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            Text(valueLabel)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private struct FastestCompletionsPreview: View {
    let entries: [FastestCompletionEntry]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(entries) { entry in
                NavigationLink(destination: UserProfileView(userId: entry.userId, userName: entry.userName)) {
                    FastestRow(entry: entry)
                }
                if entry.id != entries.last?.id {
                    Divider()
                        .padding(.leading, 60)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct FastestRow: View {
    let entry: FastestCompletionEntry

    var formattedTime: String {
        let hours = Int(entry.completionTimeHours)
        if hours < 1 {
            let minutes = Int(entry.completionTimeHours * 60)
            return "\(minutes)m"
        } else if hours < 24 {
            return "\(hours)h"
        } else {
            let days = hours / 24
            return "\(days)d"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RankBadge(rank: entry.rank)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.userName ?? entry.userEmail)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(entry.gameTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(formattedTime)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private struct RankBadge: View {
    let rank: Int

    var backgroundColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.843, blue: 0.0)
        case 2: return Color(red: 0.753, green: 0.753, blue: 0.753)
        case 3: return Color(red: 0.804, green: 0.498, blue: 0.196)
        default: return Color(.systemGray5)
        }
    }

    var textColor: Color {
        switch rank {
        case 1, 2, 3: return .black
        default: return .primary
        }
    }

    var body: some View {
        Text("\(rank)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(textColor)
            .frame(width: 28, height: 28)
            .background(backgroundColor)
            .clipShape(Circle())
    }
}

// MARK: - Activity Section Content

private struct ActivitySectionContent: View {
    @ObservedObject var viewModel: ActivityViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Activity filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ActivityFilter.allCases) { filter in
                        ActivityFilterChip(
                            filter: filter,
                            isSelected: viewModel.selectedFilter == filter
                        ) {
                            viewModel.selectedFilter = filter
                            viewModel.applyFilter()
                        }
                    }
                }
            }

            // Activity content
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if viewModel.activities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No activity yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ActivityPreview(activities: Array(viewModel.activities.prefix(10)))
            }
        }
    }
}

private struct ActivityFilterChip: View {
    let filter: ActivityFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(filter.title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

private struct ActivityPreview: View {
    let activities: [ActivityEntry]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(activities) { activity in
                NavigationLink(destination: UserProfileView(userId: activity.userId, userName: activity.userName)) {
                    ActivityRow(activity: activity)
                }
                if activity.id != activities.last?.id {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct ActivityRow: View {
    let activity: ActivityEntry

    var icon: String {
        activity.type == "TROPHY" ? "trophy.fill" : "star.fill"
    }

    var iconColor: Color {
        if activity.type == "TROPHY" {
            return Color(red: 0.898, green: 0.894, blue: 0.886)
        }
        if let tier = activity.achievementTier {
            switch tier {
            case .PLATINUM: return Color(red: 0.898, green: 0.894, blue: 0.886)
            case .GOLD: return Color(red: 1.0, green: 0.843, blue: 0.0)
            case .SILVER: return Color(red: 0.753, green: 0.753, blue: 0.753)
            case .BRONZE: return Color(red: 0.804, green: 0.498, blue: 0.196)
            }
        }
        return .yellow
    }

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: activity.earnedAt) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: activity.earnedAt) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        return activity.earnedAt
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(activity.userName ?? activity.userEmail)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if activity.type == "TROPHY" {
                    Text("Earned a trophy in \(activity.gameTitle)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    HStack(spacing: 4) {
                        Text(activity.achievementTitle ?? "Achievement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let tier = activity.achievementTier {
                            TierBadge(tier: tier)
                        }
                    }
                    Text(activity.gameTitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .disabled(currentPage <= 1 || isLoading)
            .opacity(currentPage <= 1 ? 0.3 : 1)

            Spacer()

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
            .presentationDragIndicator(.visible)
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

// MARK: - Game Row Views

private struct GameRowView: View {
    let game: GameSummary

    var body: some View {
        HStack {
            CachedImageFixed(url: game.coverUrl, width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(game.title)
                        .font(.headline)
                        .lineLimit(1)
                    if let type = game.type, type != .BASE_GAME {
                        GameTypeBadge(type: type)
                    }
                }
                if let platform = game.platform, let slug = platform.slug {
                    HStack(spacing: 4) {
                        PlatformIcon(slug: slug, size: 12)
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

private struct GroupedGameRowView: View {
    let group: GameGroup

    private let maxPlatformIcons = 4

    var body: some View {
        HStack {
            CachedImageFixed(url: group.coverUrl, width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(group.title)
                    .font(.headline)

                HStack(spacing: 4) {
                    ForEach(group.platforms.prefix(maxPlatformIcons), id: \.id) { platform in
                        if let slug = platform.slug {
                            PlatformIcon(slug: slug, size: 14)
                        }
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

// MARK: - Global Search Results

private struct GlobalSearchResultsView: View {
    @ObservedObject var viewModel: GlobalSearchViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                }
            } else if let error = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Spacer()
                }
            } else if !viewModel.hasResults {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No results found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    // Games Section
                    if viewModel.gameCount > 0 {
                        Section {
                            ForEach(viewModel.items.filter { $0.type == .GAME }) { item in
                                NavigationLink(destination: GameFamilyRouter(title: item.title)) {
                                    SearchResultRow(item: item)
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: "gamecontroller.fill")
                                    .foregroundColor(.blue)
                                Text("Games (\(viewModel.gameCount))")
                            }
                        }
                    }

                    // Bundles Section
                    if viewModel.bundleCount > 0 {
                        Section {
                            ForEach(viewModel.items.filter { $0.type == .BUNDLE }) { item in
                                NavigationLink(destination: BundleDetailView(bundleId: item.id)) {
                                    SearchResultRow(item: item)
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: "shippingbox.fill")
                                    .foregroundColor(.purple)
                                Text("Bundles (\(viewModel.bundleCount))")
                            }
                        }
                    }

                    // DLCs Section
                    if viewModel.dlcCount > 0 {
                        Section {
                            ForEach(viewModel.items.filter { $0.type == .DLC }) { item in
                                NavigationLink(destination: DLCDetailView(dlcId: item.id)) {
                                    SearchResultRow(item: item)
                                }
                            }
                        } header: {
                            HStack {
                                Image(systemName: "puzzlepiece.extension.fill")
                                    .foregroundColor(.orange)
                                Text("DLCs (\(viewModel.dlcCount))")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

private struct SearchResultRow: View {
    let item: GlobalSearchItem

    var iconName: String {
        switch item.type {
        case .GAME: return "gamecontroller.fill"
        case .BUNDLE: return "shippingbox.fill"
        case .DLC: return "puzzlepiece.extension.fill"
        }
    }

    var iconColor: Color {
        switch item.type {
        case .GAME: return .blue
        case .BUNDLE: return .purple
        case .DLC: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            CachedImageFixed(
                url: item.coverUrl,
                width: 50,
                height: 50,
                placeholderIcon: iconName
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)

                if let slugs = item.platformSlugs, !slugs.isEmpty {
                    // Platform icons stay compact where name lists would truncate
                    HStack(spacing: 5) {
                        if let typeLabel = item.typeLabel {
                            Text(typeLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(slugs, id: \.self) { slug in
                            PlatformIcon(slug: slug, size: 16)
                        }
                        if let year = item.releaseYear {
                            Text(verbatim: "· \(year)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Game Filters Sheet

private struct GameFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss

    let platforms: [Platform]
    @Binding var selectedPlatformId: String
    @Binding var achievementFilter: AchievementFilter
    @Binding var sortOption: SortOption
    @Binding var minAchievementCount: Int
    @Binding var gameTypeFilter: GameTypeFilter
    @Binding var selectedPageSize: Int

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Platform", selection: $selectedPlatformId) {
                        Text("All Platforms").tag("")
                        ForEach(platforms) { platform in
                            Text(platform.name).tag(platform.id)
                        }
                    }

                    Picker("Type", selection: $gameTypeFilter) {
                        ForEach(GameTypeFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }

                    Picker("Achievements", selection: $achievementFilter) {
                        ForEach(AchievementFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }

                    Picker("Min Achievements", selection: $minAchievementCount) {
                        ForEach(MinAchievementOption.allCases) { option in
                            Text(option.title).tag(option.value)
                        }
                    }
                } header: {
                    Text("Filter")
                }

                Section {
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }

                    Picker("Results Per Page", selection: $selectedPageSize) {
                        ForEach(PageSizeOption.allCases) { option in
                            Text(option.title).tag(option.rawValue)
                        }
                    }
                } header: {
                    Text("Display")
                }

                Section {
                    Button("Reset Filters") {
                        selectedPlatformId = ""
                        achievementFilter = .all
                        sortOption = .titleAsc
                        minAchievementCount = 0
                        gameTypeFilter = .all
                        selectedPageSize = 25
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

