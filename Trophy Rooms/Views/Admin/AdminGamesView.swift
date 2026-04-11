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
    @State private var gameToClone: AdminGameItem?
    @State private var showingCloneSheet = false
    @State private var selectedPageSize = 50
    @State private var groupToAddPlatform: AdminGameGroup?
    @State private var showingAddPlatformSheet = false

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

                    HStack {
                        Text("\(viewModel.totalCount) games total")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Spacer()

                        Picker("Per page", selection: $selectedPageSize) {
                            ForEach(PageSizeOption.allCases) { option in
                                Text(option.title).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .font(.caption)
                    }
                }
            }

            if viewModel.isLoading && viewModel.games.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            } else if viewModel.isGrouped {
                // Grouped view
                ForEach(viewModel.groupedGames) { group in
                    if group.isSingleGame, let game = group.games.first {
                        // Single game - show flat row
                        AdminGameRow(
                            game: game,
                            isSelecting: isSelecting,
                            isSelected: selectedIds.contains(game.id),
                            onToggleSelection: { toggleSelection(game.id) },
                            onTap: {
                                if isSelecting {
                                    toggleSelection(game.id)
                                } else {
                                    gameToEdit = game
                                }
                            }
                        )
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

                                Button {
                                    gameToClone = game
                                    showingCloneSheet = true
                                } label: {
                                    Label("Clone", systemImage: "doc.on.doc")
                                }
                                .tint(.orange)
                            }
                        }
                    } else {
                        // Multiple games - show expandable group
                        DisclosureGroup {
                            ForEach(group.games) { game in
                                AdminGameRow(
                                    game: game,
                                    isSelecting: isSelecting,
                                    isSelected: selectedIds.contains(game.id),
                                    onToggleSelection: { toggleSelection(game.id) },
                                    onTap: {
                                        if isSelecting {
                                            toggleSelection(game.id)
                                        } else {
                                            gameToEdit = game
                                        }
                                    },
                                    isSubRow: true
                                )
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

                                        Button {
                                            gameToClone = game
                                            showingCloneSheet = true
                                        } label: {
                                            Label("Clone", systemImage: "doc.on.doc")
                                        }
                                        .tint(.orange)
                                    }
                                }
                            }

                            // Add Platform button
                            if !isSelecting, group.gameFamilyId != nil {
                                Button {
                                    groupToAddPlatform = group
                                    showingAddPlatformSheet = true
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.blue)
                                        Text("Add Platform")
                                            .foregroundStyle(.blue)
                                        Spacer()
                                    }
                                }
                            }
                        } label: {
                            AdminGameGroupRow(group: group)
                        }
                    }
                }
            } else {
                // Flat view
                ForEach(viewModel.filteredGames) { game in
                    AdminGameRow(
                        game: game,
                        isSelecting: isSelecting,
                        isSelected: selectedIds.contains(game.id),
                        onToggleSelection: { toggleSelection(game.id) },
                        onTap: {
                            if isSelecting {
                                toggleSelection(game.id)
                            } else {
                                gameToEdit = game
                            }
                        }
                    )
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

                            Button {
                                gameToClone = game
                                showingCloneSheet = true
                            } label: {
                                Label("Clone", systemImage: "doc.on.doc")
                            }
                            .tint(.orange)
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
        .onChange(of: selectedPageSize) {
            Task {
                await viewModel.setPageSize(selectedPageSize)
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

                        Divider()

                        Button {
                            viewModel.isGrouped.toggle()
                        } label: {
                            if viewModel.isGrouped {
                                Label("Show Flat List", systemImage: "list.bullet")
                            } else {
                                Label("Group by Family", systemImage: "rectangle.3.group")
                            }
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
                        _ = await viewModel.deleteGame(id: game.id)
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
                    _ = await viewModel.bulkDeleteGames(ids: Array(selectedIds))
                    selectedIds.removeAll()
                    isSelecting = false
                }
            }
        } message: {
            Text("Are you sure you want to delete \(selectedIds.count) game(s)? This will also delete all related achievement sets and achievements. This action cannot be undone.")
        }
        .sheet(isPresented: $showingCloneSheet) {
            if let game = gameToClone {
                CloneGameSheet(viewModel: viewModel, game: game) {
                    showingCloneSheet = false
                    gameToClone = nil
                }
            }
        }
        .sheet(isPresented: $showingAddPlatformSheet) {
            if let group = groupToAddPlatform, let gameFamilyId = group.gameFamilyId {
                AddPlatformSheet(
                    viewModel: viewModel,
                    gameFamilyId: gameFamilyId,
                    gameTitle: group.title,
                    existingPlatformIds: Set(group.games.compactMap { $0.platformId })
                ) {
                    showingAddPlatformSheet = false
                    groupToAddPlatform = nil
                }
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

// MARK: - Clone Game Sheet
struct CloneGameSheet: View {
    @ObservedObject var viewModel: AdminGamesViewModel
    let game: AdminGameItem
    let onDismiss: () -> Void

    @State private var selectedPlatformId: String = ""
    @State private var copyAchievementSets = false
    @State private var isCloning = false

    var availablePlatforms: [AdminPlatform] {
        // Filter out the current platform
        viewModel.platforms.filter { $0.id != game.platformId }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        AsyncImage(url: game.coverUrl.flatMap { URL(string: $0) }) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(game.title)
                                .font(.headline)
                            if let platformName = game.platformName {
                                Text("Current: \(platformName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Source Game")
                }

                Section {
                    Picker("Target Platform", selection: $selectedPlatformId) {
                        Text("Select a platform").tag("")
                        ForEach(availablePlatforms) { platform in
                            Text(platform.name).tag(platform.id)
                        }
                    }
                } header: {
                    Text("Clone To")
                }

                Section {
                    Toggle("Copy Achievement Sets", isOn: $copyAchievementSets)
                } footer: {
                    Text("If enabled, all achievement sets and their achievements will be copied to the new game.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Clone Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .disabled(isCloning)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clone") {
                        Task {
                            isCloning = true
                            let success = await viewModel.cloneGameToPlatform(
                                gameId: game.id,
                                targetPlatformId: selectedPlatformId,
                                copyAchievementSets: copyAchievementSets
                            )
                            isCloning = false
                            if success {
                                onDismiss()
                            }
                        }
                    }
                    .disabled(selectedPlatformId.isEmpty || isCloning)
                }
            }
            .interactiveDismissDisabled(isCloning)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Add Platform Sheet

struct AddPlatformSheet: View {
    @ObservedObject var viewModel: AdminGamesViewModel
    let gameFamilyId: String
    let gameTitle: String
    let existingPlatformIds: Set<String>
    let onDismiss: () -> Void

    @State private var selectedPlatformId: String = ""
    @State private var isAdding = false

    var availablePlatforms: [AdminPlatform] {
        // Filter out platforms that already have this game
        viewModel.platforms.filter { !existingPlatformIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(gameTitle)
                        .font(.headline)
                } header: {
                    Text("Game Family")
                }

                Section {
                    if availablePlatforms.isEmpty {
                        Text("All platforms already have this game")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Platform", selection: $selectedPlatformId) {
                            Text("Select a platform").tag("")
                            ForEach(availablePlatforms) { platform in
                                HStack {
                                    PlatformIcon(slug: platform.slug, size: 16)
                                    Text(platform.name)
                                }
                                .tag(platform.id)
                            }
                        }
                    }
                } header: {
                    Text("Add Platform")
                } footer: {
                    Text("Select a platform to add \(gameTitle) to.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Platform")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .disabled(isAdding)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            isAdding = true
                            let success = await viewModel.addGameToFamily(
                                gameFamilyId: gameFamilyId,
                                platformId: selectedPlatformId
                            )
                            isAdding = false
                            if success {
                                onDismiss()
                            }
                        }
                    }
                    .disabled(selectedPlatformId.isEmpty || isAdding)
                }
            }
            .interactiveDismissDisabled(isAdding)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Admin Game Row

private struct AdminGameRow: View {
    let game: AdminGameItem
    let isSelecting: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onTap: () -> Void
    var isSubRow: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray)
                    .onTapGesture {
                        onToggleSelection()
                    }
            }

            if !isSubRow {
                AsyncImage(url: game.coverUrl.flatMap { URL(string: $0) }) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                if isSubRow {
                    // For sub-rows, just show platform name
                    if let platformName = game.platformName {
                        HStack(spacing: 6) {
                            if let slug = game.platformSlug {
                                PlatformIcon(slug: slug, size: 16)
                            }
                            Text(platformName)
                                .font(.subheadline)
                        }
                    }
                    Text("\(game.achievementSetCount) sets")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
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
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Admin Game Group Row

private struct AdminGameGroupRow: View {
    let group: AdminGameGroup

    private let maxPlatformIcons = 5

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: group.coverUrl.flatMap { URL(string: $0) }) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(group.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    ForEach(Array(group.games.prefix(maxPlatformIcons)), id: \.id) { game in
                        if let slug = game.platformSlug {
                            PlatformIcon(slug: slug, size: 14)
                        }
                    }
                    if group.games.count > maxPlatformIcons {
                        Text("+\(group.games.count - maxPlatformIcons)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("\(group.games.count) platforms, \(group.totalAchievementSets) sets")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AdminGamesView()
    }
}
