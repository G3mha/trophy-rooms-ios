import SwiftUI
import ClerkKit

private enum CollectionTab: Int, Hashable {
    case collection = 0
    case buylist = 1
}

struct CollectionView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var collectionViewModel = CollectionViewModel()
    @StateObject private var buylistViewModel = BuylistViewModel()
    @StateObject private var expandedSections = ExpandedSectionsState()
    @State private var showAuth = false
    @State private var editingItem: CollectionItem?
    @State private var editingItemVersions: [GameVersion] = []
    @State private var showEditSheet = false
    @State private var showPurchasedSheet = false
    @State private var selectedItemForPurchase: BuylistItem?
    @State private var selectedTab: CollectionTab = .collection
    @AppStorage("collection_showStats") private var showCollectionStats = true
    @AppStorage("buylist_showStats") private var showBuylistStats = true

    private let collectionTabs: [InlineTab<CollectionTab>] = [
        InlineTab(title: "My Collection", icon: "archivebox.fill", value: .collection),
        InlineTab(title: "Buylist", icon: "cart.fill", value: .buylist)
    ]

    var body: some View {
        Group {
            if clerk.user == nil {
                signInPrompt
            } else {
                VStack(spacing: 0) {
                    // Tab picker
                    InlineTabPicker(selectedTab: $selectedTab, tabs: collectionTabs)

                    // Tab content
                    TabView(selection: $selectedTab) {
                        collectionContent
                            .tag(CollectionTab.collection)

                        buylistContent
                            .tag(CollectionTab.buylist)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
        }
        .navigationBar(title: "Collection")
        .sheet(isPresented: $showAuth) {
            AuthView()
        }
        .sheet(isPresented: $showEditSheet) {
            if let item = editingItem {
                AddToCollectionSheet(
                    gameId: item.gameId,
                    gameTitle: item.game.title,
                    editingItem: item,
                    versions: editingItemVersions
                ) {
                    Task {
                        await collectionViewModel.fetchCollection()
                    }
                }
            }
        }
        .sheet(isPresented: $showPurchasedSheet) {
            if let item = selectedItemForPurchase {
                MarkAsPurchasedSheet(item: item) {
                    Task {
                        await buylistViewModel.fetchBuylist()
                        await buylistViewModel.fetchStats()
                    }
                }
            }
        }
        .task {
            if clerk.user != nil {
                if !collectionViewModel.hasLoadedOnce {
                    await collectionViewModel.fetchCollection()
                }
                await buylistViewModel.fetchBuylist()
                await buylistViewModel.fetchStats()
            }
        }
        .onChange(of: clerk.user?.id) {
            if clerk.user != nil {
                Task {
                    await collectionViewModel.fetchCollection()
                    await buylistViewModel.fetchBuylist()
                    await buylistViewModel.fetchStats()
                }
            }
        }
    }

    // MARK: - Sign In Prompt

    private var signInPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Sign in to view your collection")
                .font(.headline)
            Button("Sign In") {
                showAuth = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Collection Content

    @ViewBuilder
    private var collectionContent: some View {
        let showLoading = collectionViewModel.isLoading || !collectionViewModel.hasLoadedOnce

        if showLoading {
            ProgressView("Loading collection...")
        } else if let error = collectionViewModel.errorMessage {
            VStack(spacing: 16) {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                Button("Retry") {
                    Task {
                        await collectionViewModel.fetchCollection()
                    }
                }
            }
        } else if collectionViewModel.collectionItems.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "archivebox")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Your collection is empty")
                    .font(.headline)
                Text("Add physical games to track your collection")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        } else {
            VStack(spacing: 0) {
                // Stats header
                if let stats = collectionViewModel.stats {
                    CollapsibleStatsBar(
                        stats: collectionStatItems(from: stats),
                        collapsedSummary: "\(stats.totalItems) items · \(stats.completeCount) CIB",
                        isExpanded: $showCollectionStats
                    )
                }

                // Sort and group controls
                SortGroupControls(
                    selectedSortOption: $collectionViewModel.selectedSortOption,
                    groupByPlatform: $collectionViewModel.groupByPlatform,
                    onSortChanged: {}
                )

                // Filter bar
                CollectionFilterBar(
                    selectedRegion: $collectionViewModel.selectedRegion,
                    selectedPlatformId: $collectionViewModel.selectedPlatformId,
                    availablePlatforms: collectionViewModel.availablePlatforms,
                    showSealedOnly: $collectionViewModel.showSealedOnly,
                    showCompleteOnly: $collectionViewModel.showCompleteOnly
                )

                // Collection list
                List {
                    if collectionViewModel.groupByPlatform {
                        ForEach(Array(collectionViewModel.groupedItems.enumerated()), id: \.offset) { _, group in
                            let sectionId = group.platform?.id ?? "other"
                            Section {
                                if expandedSections.isExpanded(sectionId) {
                                    ForEach(group.items) { item in
                                        NavigationLink(destination: GameDetailView(gameId: item.gameId)) {
                                            CollectionItemRow(item: item)
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                editingItem = item
                                                Task {
                                                    await fetchVersionsForGame(gameId: item.gameId)
                                                    showEditSheet = true
                                                }
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                    }
                                    .onDelete { indexSet in
                                        for index in indexSet {
                                            let item = group.items[index]
                                            Task {
                                                await collectionViewModel.removeFromCollection(id: item.id)
                                            }
                                        }
                                    }
                                }
                            } header: {
                                PlatformSectionHeader(
                                    name: group.platform?.name,
                                    slug: group.platform?.slug,
                                    count: group.items.count,
                                    isExpanded: expandedSections.isExpanded(sectionId),
                                    onToggle: { expandedSections.toggle(sectionId) }
                                )
                            }
                        }
                        .onAppear {
                            let ids = collectionViewModel.groupedItems.map { $0.platform?.id ?? "other" }
                            expandedSections.expandAll(ids)
                        }
                    } else {
                        ForEach(collectionViewModel.filteredItems) { item in
                            NavigationLink(destination: GameDetailView(gameId: item.gameId)) {
                                CollectionItemRow(item: item)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingItem = item
                                    Task {
                                        await fetchVersionsForGame(gameId: item.gameId)
                                        showEditSheet = true
                                    }
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let item = collectionViewModel.filteredItems[index]
                                Task {
                                    await collectionViewModel.removeFromCollection(id: item.id)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Buylist Content

    @ViewBuilder
    private var buylistContent: some View {
        if buylistViewModel.isLoading {
            ProgressView("Loading buylist...")
        } else if let error = buylistViewModel.errorMessage {
            VStack(spacing: 16) {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                Button("Retry") {
                    Task {
                        await buylistViewModel.fetchBuylist()
                        await buylistViewModel.fetchStats()
                    }
                }
            }
        } else if buylistViewModel.buylistItems.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "cart")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Your buylist is empty")
                    .font(.headline)
                Text("Browse games, DLCs, and bundles to add them to your buylist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        } else {
            VStack(spacing: 0) {
                // Stats bar
                if let stats = buylistViewModel.stats {
                    CollapsibleStatsBar(
                        stats: buylistStatItems(from: stats),
                        collapsedSummary: "\(stats.totalItems) items · \(String(format: "$%.2f", stats.totalEstimatedCost))",
                        isExpanded: $showBuylistStats
                    )
                }

                // Filter pills
                BuylistFilterBar(
                    selectedPriority: $buylistViewModel.selectedPriority,
                    priorityCounts: buylistViewModel.priorityCounts,
                    selectedItemType: $buylistViewModel.selectedItemType,
                    itemTypeCounts: buylistViewModel.itemTypeCounts,
                    selectedSortOption: $buylistViewModel.selectedSortOption,
                    groupByPlatform: $buylistViewModel.groupByPlatform,
                    onSortChanged: {
                        Task {
                            await buylistViewModel.fetchBuylist()
                        }
                    }
                )

                // Items list
                List {
                    if buylistViewModel.groupByPlatform {
                        ForEach(Array(buylistViewModel.groupedItems.enumerated()), id: \.offset) { _, group in
                            let sectionId = group.platform?.id ?? "other"
                            Section {
                                if expandedSections.isExpanded(sectionId) {
                                    ForEach(group.items) { item in
                                        NavigationLink(destination: destinationView(for: item)) {
                                            BuylistItemRow(item: item, showPlatform: false)
                                        }
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                selectedItemForPurchase = item
                                                showPurchasedSheet = true
                                            } label: {
                                                Label("Purchased", systemImage: "checkmark")
                                            }
                                            .tint(.green)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                Task {
                                                    await buylistViewModel.removeFromBuylist(id: item.id)
                                                }
                                            } label: {
                                                Label("Remove", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            } header: {
                                PlatformSectionHeader(
                                    name: group.platform?.name,
                                    slug: group.platform?.slug,
                                    count: group.items.count,
                                    isExpanded: expandedSections.isExpanded(sectionId),
                                    onToggle: { expandedSections.toggle(sectionId) }
                                )
                            }
                        }
                        .onAppear {
                            let ids = buylistViewModel.groupedItems.map { $0.platform?.id ?? "other" }
                            expandedSections.expandAll(ids)
                        }
                    } else {
                        ForEach(buylistViewModel.filteredItems) { item in
                            NavigationLink(destination: destinationView(for: item)) {
                                BuylistItemRow(item: item, showPlatform: true)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    selectedItemForPurchase = item
                                    showPurchasedSheet = true
                                } label: {
                                    Label("Purchased", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await buylistViewModel.removeFromBuylist(id: item.id)
                                    }
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Helper Functions

    private func collectionStatItems(from stats: CollectionStats) -> [StatItem] {
        var items = [
            StatItem(title: "Total", value: "\(stats.totalItems)", icon: "archivebox.fill", color: .blue),
            StatItem(title: "Sealed", value: "\(stats.sealedCount)", icon: "seal.fill", color: .purple),
            StatItem(title: "Complete", value: "\(stats.completeCount)", icon: "checkmark.seal.fill", color: .green),
        ]

        for regionCount in stats.byRegion {
            items.append(StatItem(
                title: regionCount.region.displayName,
                value: "\(regionCount.count)",
                icon: "globe",
                color: regionColor(for: regionCount.region)
            ))
        }

        return items
    }

    private func buylistStatItems(from stats: BuylistStats) -> [StatItem] {
        [
            StatItem(title: "Total", value: "\(stats.totalItems)", icon: "cart.fill", color: .blue),
            StatItem(title: "Games", value: "\(stats.gameCount)", icon: "gamecontroller.fill", color: .blue),
            StatItem(title: "Bundles", value: "\(stats.bundleCount)", icon: "shippingbox.fill", color: .orange),
            StatItem(title: "DLCs", value: "\(stats.dlcCount)", icon: "puzzlepiece.extension.fill", color: .purple),
            StatItem(title: "High", value: "\(stats.highPriorityCount)", icon: "exclamationmark.circle.fill", color: .red),
            StatItem(title: "Est. Total", value: String(format: "$%.2f", stats.totalEstimatedCost), icon: "dollarsign.circle.fill", color: .green),
        ]
    }

    private func regionColor(for region: GameRegion) -> Color {
        switch region {
        case .NTSC_U: return .blue
        case .PAL: return .green
        case .NTSC_J: return .red
        case .OTHER: return .gray
        }
    }

    @ViewBuilder
    private func destinationView(for item: BuylistItem) -> some View {
        switch item.itemType {
        case .GAME:
            if let gameId = item.gameId {
                GameDetailView(gameId: gameId)
            } else {
                Text("Game not found")
            }
        case .DLC:
            Text("DLC: \(item.displayTitle)")
        case .BUNDLE:
            if let bundleId = item.bundleId {
                BundleDetailView(bundleId: bundleId)
            } else {
                Text("Bundle not found")
            }
        }
    }

    private func fetchVersionsForGame(gameId: String) async {
        let query = """
        query GetGameVersions($gameId: ID!) {
            gameVersions(gameId: $gameId) {
                id
                name
                slug
                description
                coverUrl
                effectiveCoverUrl
                releaseDate
                includedDlc
                isDefault
                achievementSetCount
            }
        }
        """

        do {
            let response: GameVersionsResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["gameId": gameId]
            )
            DispatchQueue.main.async {
                self.editingItemVersions = response.gameVersions
            }
        } catch {
            DispatchQueue.main.async {
                self.editingItemVersions = []
            }
        }
    }
}

// MARK: - Collection Filter Bar

private struct CollectionFilterBar: View {
    @Binding var selectedRegion: GameRegion?
    @Binding var selectedPlatformId: String?
    let availablePlatforms: [Platform]
    @Binding var showSealedOnly: Bool
    @Binding var showCompleteOnly: Bool

    var selectedPlatformName: String? {
        availablePlatforms.first { $0.id == selectedPlatformId }?.name
    }

    var hasActiveFilters: Bool {
        selectedRegion != nil || selectedPlatformId != nil || showSealedOnly || showCompleteOnly
    }

    var body: some View {
        FilterBarContainer {
            if !availablePlatforms.isEmpty {
                Menu {
                    Button("All Platforms") {
                        selectedPlatformId = nil
                    }
                    ForEach(availablePlatforms) { platform in
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

            Menu {
                Button("All Regions") {
                    selectedRegion = nil
                }
                ForEach(GameRegion.allCases, id: \.self) { region in
                    Button(region.displayName) {
                        selectedRegion = region
                    }
                }
            } label: {
                FilterChip(
                    title: selectedRegion?.displayName ?? "Region",
                    isActive: selectedRegion != nil
                )
            }

            Button {
                showSealedOnly.toggle()
            } label: {
                FilterChip(title: "Sealed", isActive: showSealedOnly, activeColor: .purple)
            }

            Button {
                showCompleteOnly.toggle()
            } label: {
                FilterChip(title: "Complete", isActive: showCompleteOnly, activeColor: .green)
            }

            if hasActiveFilters {
                Button {
                    selectedRegion = nil
                    selectedPlatformId = nil
                    showSealedOnly = false
                    showCompleteOnly = false
                } label: {
                    Text("Clear")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - Buylist Filter Bar

private struct BuylistFilterBar: View {
    @Binding var selectedPriority: BuylistPriority?
    let priorityCounts: [BuylistPriority: Int]
    @Binding var selectedItemType: BuylistItemType?
    let itemTypeCounts: [BuylistItemType: Int]
    @Binding var selectedSortOption: BuylistSortOption
    @Binding var groupByPlatform: Bool
    let onSortChanged: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SortGroupControls(
                selectedSortOption: $selectedSortOption,
                groupByPlatform: $groupByPlatform,
                onSortChanged: onSortChanged
            )

            FilterBarContainer {
                FilterPill(
                    title: "All",
                    count: priorityCounts.values.reduce(0, +),
                    isSelected: selectedPriority == nil && selectedItemType == nil,
                    color: filterAllColor
                ) {
                    selectedPriority = nil
                    selectedItemType = nil
                }

                ForEach(BuylistPriority.allCases, id: \.self) { priority in
                    let count = priorityCounts[priority] ?? 0
                    if count > 0 {
                        FilterPill(
                            title: priority.displayName,
                            count: count,
                            isSelected: selectedPriority == priority,
                            color: priorityColor(for: priority)
                        ) {
                            selectedPriority = priority
                        }
                    }
                }

                Divider().frame(height: 24)

                ForEach(BuylistItemType.allCases, id: \.self) { itemType in
                    let count = itemTypeCounts[itemType] ?? 0
                    if count > 0 {
                        FilterPill(
                            title: itemType.displayName,
                            count: count,
                            isSelected: selectedItemType == itemType,
                            color: itemTypeColor(for: itemType)
                        ) {
                            selectedItemType = itemType
                        }
                    }
                }
            }
        }
    }

    func priorityColor(for priority: BuylistPriority) -> Color {
        switch priority {
        case .HIGH: return .red
        case .MEDIUM: return .orange
        case .LOW: return .green
        }
    }

    func itemTypeColor(for itemType: BuylistItemType) -> Color {
        switch itemType {
        case .GAME: return .blue
        case .DLC: return .purple
        case .BUNDLE: return .pink
        }
    }
}

// MARK: - Collection Item Row

private struct CollectionItemRow: View {
    let item: CollectionItem

    var body: some View {
        HStack(spacing: 12) {
            CoverImage.gameRow(url: item.game.coverUrl)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.game.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    RegionBadge(region: item.region)

                    if let version = item.gameVersion {
                        Badge(text: version.name, color: .blue)
                    }

                    if item.isSealed {
                        Badge(text: "Sealed", color: .purple)
                    }

                    if item.isComplete {
                        Badge(text: "CIB", color: .green)
                    }
                }

                HStack(spacing: 8) {
                    if item.hasDisc {
                        Image(systemName: "opticaldisc")
                            .font(.caption)
                    }
                    if item.hasBox {
                        Image(systemName: "shippingbox")
                            .font(.caption)
                    }
                    if item.hasManual {
                        Image(systemName: "book.closed")
                            .font(.caption)
                    }
                    if item.hasExtras {
                        Image(systemName: "gift")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }

            Spacer()

            if let platform = item.platform, let slug = platform.slug {
                PlatformIcon(slug: slug, size: 24)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Badges

private struct RegionBadge: View {
    let region: GameRegion

    var body: some View {
        Text(region.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(regionColor.opacity(0.15))
            .foregroundColor(regionColor)
            .cornerRadius(4)
    }

    var regionColor: Color {
        switch region {
        case .NTSC_U: return .blue
        case .PAL: return .green
        case .NTSC_J: return .red
        case .OTHER: return .gray
        }
    }
}

private struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}
