import SwiftUI
import ClerkKit

struct LibraryView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = LibraryViewModel()
    @StateObject private var expandedSections = ExpandedSectionsState()
    @State private var showAuth = false
    @State private var editingItem: LibraryItem?
    @State private var showStatusPicker = false
    @AppStorage("library_showStats") private var showStats = true

    var body: some View {
        Group {
            if clerk.user == nil {
                VStack(spacing: 16) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Sign in to view your library")
                        .font(.headline)
                    Button("Sign In") {
                        showAuth = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.isLoading {
                ProgressView("Loading library...")
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await viewModel.fetchLibrary()
                        }
                    }
                }
            } else if viewModel.libraryItems.isEmpty {
                ContentUnavailableView(
                    "Your Library Is Empty",
                    systemImage: "books.vertical",
                    description: Text("Browse games and add them to your library")
                )
            } else {
                VStack(spacing: 0) {
                    CollapsibleStatsBar(
                        stats: libraryStatItems(
                            totalItems: viewModel.libraryItems.count,
                            statusCounts: viewModel.statusCounts
                        ),
                        collapsedSummary: "\(viewModel.libraryItems.count) games",
                        isExpanded: $showStats
                    )

                    // Sort and group controls
                    SortGroupControls(
                        selectedSortOption: $viewModel.selectedSortOption,
                        groupByPlatform: $viewModel.groupByPlatform,
                        onSortChanged: {}
                    )

                    // Status and platform filter pills
                    LibraryFilterView(
                        selectedStatus: $viewModel.selectedStatus,
                        statusCounts: viewModel.statusCounts,
                        selectedPlatformId: $viewModel.selectedPlatformId,
                        availablePlatforms: viewModel.availablePlatforms
                    )

                    // Game grid
                    if viewModel.groupByPlatform {
                        LibraryGroupedGrid(
                            groups: viewModel.groupedItems,
                            expandedSections: expandedSections,
                            onRefresh: {
                                await viewModel.fetchLibrary(forceRefresh: true)
                            },
                            onEdit: { item in
                                editingItem = item
                                showStatusPicker = true
                            },
                            onDelete: { item in
                                Task {
                                    await viewModel.clearGameStatus(gameId: item.gameId)
                                }
                            }
                        )
                    } else {
                        LibraryFlatGrid(
                            items: viewModel.filteredItems,
                            onRefresh: {
                                await viewModel.fetchLibrary(forceRefresh: true)
                            },
                            onEdit: { item in
                                editingItem = item
                                showStatusPicker = true
                            },
                            onDelete: { item in
                                Task {
                                    await viewModel.clearGameStatus(gameId: item.gameId)
                                }
                            }
                        )
                    }
                }
            }
        }
        .navigationBar(title: "Library")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(destination: PlayJournalView()) {
                    Image(systemName: "calendar.badge.clock")
                }
            }
        }
        .sheet(isPresented: $showAuth) {
            AuthView()
        }
        .sheet(isPresented: $showStatusPicker) {
            if let item = editingItem {
                StatusPickerSheet(
                    currentStatus: item.status,
                    currentPlatformId: item.platformId,
                    currentVersionId: item.gameVersionId,
                    versions: [],
                    onSelect: { status, platformId, versionId in
                        Task {
                            await viewModel.setGameStatus(gameId: item.gameId, status: status, platformId: platformId, gameVersionId: versionId)
                        }
                    },
                    onClear: {
                        Task {
                            await viewModel.clearGameStatus(gameId: item.gameId)
                        }
                    }
                )
            }
        }
        .task {
            if clerk.user != nil {
                await viewModel.fetchLibrary()
            }
        }
        .onChange(of: clerk.user?.id) {
            if clerk.user != nil {
                Task {
                    await viewModel.fetchLibrary(forceRefresh: true)
                }
            }
        }
    }

    private func libraryStatItems(totalItems: Int, statusCounts: [GameStatus: Int]) -> [StatItem] {
        var items = [StatItem(title: "Total", value: "\(totalItems)", icon: "books.vertical.fill", color: .blue)]

        for status in GameStatus.allCases {
            let count = statusCounts[status] ?? 0
            if count > 0 {
                items.append(StatItem(
                    title: status.displayName,
                    value: "\(count)",
                    icon: statusIcon(for: status),
                    color: statusColor(for: status)
                ))
            }
        }

        return items
    }

    private func statusColor(for status: GameStatus) -> Color {
        switch status {
        case .BACKLOG: return .blue
        case .PLAYING: return .green
        case .PAUSED: return .orange
        case .COMPLETED: return .purple
        case .DROPPED: return .gray
        }
    }

    private func statusIcon(for status: GameStatus) -> String {
        switch status {
        case .BACKLOG: return "tray.full.fill"
        case .PLAYING: return "play.circle.fill"
        case .PAUSED: return "pause.circle.fill"
        case .COMPLETED: return "checkmark.circle.fill"
        case .DROPPED: return "xmark.circle.fill"
        }
    }
}

private struct LibraryFilterView: View {
    @Binding var selectedStatus: GameStatus?
    let statusCounts: [GameStatus: Int]
    @Binding var selectedPlatformId: String?
    let availablePlatforms: [(id: String, name: String, slug: String?)]

    var selectedPlatformName: String? {
        availablePlatforms.first { $0.id == selectedPlatformId }?.name
    }

    var body: some View {
        FilterBarContainer {
            // All filter
            FilterPill(
                title: "All",
                count: statusCounts.values.reduce(0, +),
                isSelected: selectedStatus == nil && selectedPlatformId == nil,
                color: filterAllColor
            ) {
                selectedStatus = nil
                selectedPlatformId = nil
            }

            // Status filters
            ForEach(GameStatus.allCases, id: \.self) { status in
                let count = statusCounts[status] ?? 0
                if count > 0 {
                    FilterPill(
                        title: status.displayName,
                        count: count,
                        isSelected: selectedStatus == status,
                        color: statusColor(for: status)
                    ) {
                        selectedStatus = status
                    }
                }
            }

            // Platform filter menu
            if !availablePlatforms.isEmpty {
                Menu {
                    Button("All Platforms") {
                        selectedPlatformId = nil
                    }
                    ForEach(availablePlatforms, id: \.id) { platform in
                        Button(platform.name) {
                            selectedPlatformId = platform.id
                        }
                    }
                } label: {
                    FilterChip(
                        title: selectedPlatformName ?? "Platform",
                        isActive: selectedPlatformId != nil
                    )
                }
            }
        }
    }

    func statusColor(for status: GameStatus) -> Color {
        switch status {
        case .BACKLOG: return .blue
        case .PLAYING: return .green
        case .PAUSED: return .orange
        case .COMPLETED: return .purple
        case .DROPPED: return .gray
        }
    }
}

private struct LibraryItemRow: View {
    let item: LibraryItem

    var body: some View {
        HStack(spacing: 12) {
            CoverImage.gameRow(url: item.gameCoverUrl)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.gameTitle)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    StatusBadge(status: item.status)
                    if let versionName = item.gameVersionName {
                        VersionBadge(name: versionName)
                    }
                }

                Text("\(item.achievementCount) achievements")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Platform icon on the right
            if let platformSlug = item.platformSlug {
                PlatformIcon(slug: platformSlug, size: 24)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct PlatformBadge: View {
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gamecontroller")
                .font(.caption2)
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.15))
        .foregroundColor(.secondary)
        .cornerRadius(8)
    }
}

struct StatusBadge: View {
    let status: GameStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.caption2)
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .foregroundColor(statusColor)
        .cornerRadius(8)
    }

    var statusColor: Color {
        switch status {
        case .BACKLOG: return .blue
        case .PLAYING: return .green
        case .PAUSED: return .orange
        case .COMPLETED: return .purple
        case .DROPPED: return .gray
        }
    }
}

struct VersionBadge: View {
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "square.stack.3d.up")
                .font(.caption2)
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.indigo.opacity(0.15))
        .foregroundColor(.indigo)
        .cornerRadius(8)
    }
}

// MARK: - Library Grid Components

private struct LibraryGroupedGrid: View {
    let groups: [(platform: (id: String, name: String, slug: String?)?, items: [LibraryItem])]
    let expandedSections: ExpandedSectionsState
    let onRefresh: () async -> Void
    let onEdit: (LibraryItem) -> Void
    let onDelete: (LibraryItem) -> Void

    private let columns = GameCoverGridLayout.columns()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    let sectionId = group.platform?.id ?? "other"

                    Section {
                        if expandedSections.isExpanded(sectionId) {
                            LibraryItemsGrid(
                                items: group.items,
                                onEdit: onEdit,
                                onDelete: onDelete
                            )
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    } header: {
                        PlatformGridSectionHeader(
                            name: group.platform?.name,
                            slug: group.platform?.slug,
                            count: group.items.count,
                            isExpanded: expandedSections.isExpanded(sectionId),
                            onToggle: { expandedSections.toggle(sectionId) }
                        )
                    }
                }
            }
        }
        .contentMargins(.bottom, 100, for: .scrollContent)
        .ignoresSafeArea(edges: .bottom)
        .refreshable {
            await onRefresh()
        }
        .onAppear {
            let ids = groups.map { $0.platform?.id ?? "other" }
            expandedSections.expandAll(ids)
        }
    }
}

private struct LibraryFlatGrid: View {
    let items: [LibraryItem]
    let onRefresh: () async -> Void
    let onEdit: (LibraryItem) -> Void
    let onDelete: (LibraryItem) -> Void

    private let columns = GameCoverGridLayout.columns()

    var body: some View {
        ScrollView {
            LibraryItemsGrid(
                items: items,
                onEdit: onEdit,
                onDelete: onDelete
            )
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .contentMargins(.bottom, 100, for: .scrollContent)
        .ignoresSafeArea(edges: .bottom)
        .refreshable {
            await onRefresh()
        }
    }
}

/// Grid of library games where entries from the same compilation bundle
/// collapse into a stack (same interaction as the Collection grid).
private struct LibraryItemsGrid: View {
    let items: [LibraryItem]
    let onEdit: (LibraryItem) -> Void
    let onDelete: (LibraryItem) -> Void

    @State private var expandedBundleIds: Set<String> = []

    private let columns = GameCoverGridLayout.columns()

    private enum GridCell: Identifiable {
        case item(LibraryItem)
        case stack(LibraryBundleRef, items: [LibraryItem])

        var id: String {
            switch self {
            case .item(let item): return "item-\(item.id)"
            case .stack(let bundle, _): return "stack-\(bundle.id)"
            }
        }
    }

    /// Items sharing a bundle (2+) collapse into one stack, keeping the
    /// position of their first member; each item joins at most one stack.
    private var cells: [GridCell] {
        var bundleCounts: [String: Int] = [:]
        for item in items {
            for bundle in item.bundles ?? [] {
                bundleCounts[bundle.id, default: 0] += 1
            }
        }

        func stackBundle(for item: LibraryItem) -> LibraryBundleRef? {
            (item.bundles ?? [])
                .filter { bundleCounts[$0.id, default: 0] >= 2 }
                .max { bundleCounts[$0.id, default: 0] < bundleCounts[$1.id, default: 0] }
        }

        var cells: [GridCell] = []
        var stackedItems: [String: [LibraryItem]] = [:]
        var stackOrder: [LibraryBundleRef] = []

        for item in items {
            if let bundle = stackBundle(for: item) {
                if stackedItems[bundle.id] == nil {
                    stackOrder.append(bundle)
                }
                stackedItems[bundle.id, default: []].append(item)
            }
        }

        var placedStacks: Set<String> = []
        for item in items {
            if let bundle = stackBundle(for: item) {
                if !placedStacks.contains(bundle.id) {
                    placedStacks.insert(bundle.id)
                    cells.append(.stack(bundle, items: stackedItems[bundle.id] ?? []))
                    if expandedBundleIds.contains(bundle.id) {
                        for member in stackedItems[bundle.id] ?? [] {
                            cells.append(.item(member))
                        }
                    }
                }
            } else {
                cells.append(.item(item))
            }
        }
        return cells
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(cells) { cell in
                switch cell {
                case .item(let item):
                    LibraryGridCell(
                        item: item,
                        onEdit: { onEdit(item) },
                        onDelete: { onDelete(item) }
                    )
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                case .stack(let bundle, let members):
                    LibraryBundleStackCell(
                        bundle: bundle,
                        count: members.count,
                        isExpanded: expandedBundleIds.contains(bundle.id),
                        onToggle: {
                            withAnimation(.snappy) {
                                if expandedBundleIds.contains(bundle.id) {
                                    expandedBundleIds.remove(bundle.id)
                                } else {
                                    expandedBundleIds.insert(bundle.id)
                                }
                            }
                        }
                    )
                }
            }
        }
    }
}

/// Compilation stack in the library grid: bundle cover with cards peeking
/// out behind, fanning open to the member games on tap.
private struct LibraryBundleStackCell: View {
    let bundle: LibraryBundleRef
    let count: Int
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemFill))
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .rotationEffect(.degrees(isExpanded ? 0 : 5))
                    .offset(x: isExpanded ? 0 : 7, y: isExpanded ? 0 : -3)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemFill))
                    .aspectRatio(3 / 4, contentMode: .fit)
                    .rotationEffect(.degrees(isExpanded ? 0 : 2.5))
                    .offset(x: isExpanded ? 0 : 3, y: isExpanded ? 0 : -1.5)

                GameCoverCell(coverUrl: bundle.coverUrl, title: bundle.name) {
                    VStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 10))
                            Text("\(count)")
                                .font(.system(size: 10, weight: .bold))
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(4)
                        .background(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct LibraryGridCell: View {
    let item: LibraryItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    @Namespace private var zoomNamespace

    var body: some View {
        NavigationLink(
            destination: GameDetailView(gameId: item.gameId)
                .navigationTransition(.zoom(sourceID: item.id, in: zoomNamespace))
        ) {
            GameCoverCell(coverUrl: item.gameCoverUrl, title: item.gameTitle) {
                StatusOverlayBadge(status: item.status)
            }
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    onEdit()
                } label: {
                    Label("Change Status", systemImage: "pencil")
                }

                Divider()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Remove from Library", systemImage: "trash")
                }
            }
        }
        .matchedTransitionSource(id: item.id, in: zoomNamespace)
    }
}
