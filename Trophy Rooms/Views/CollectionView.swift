import SwiftUI

private enum CollectionTab: Int, Hashable {
    case collection = 0
    case buylist = 1
    case sellList = 2
}

struct CollectionView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var collectionViewModel = CollectionViewModel()
    @StateObject private var buylistViewModel = BuylistViewModel()
    @StateObject private var sellListViewModel = SellListViewModel()
    @StateObject private var collectionExpandedSections = ExpandedSectionsState()
    @StateObject private var buylistExpandedSections = ExpandedSectionsState()
    @StateObject private var sellListExpandedSections = ExpandedSectionsState()
    @State private var showAuth = false
    @State private var editingItem: CollectionItem?
    @State private var editingItemVersions: [GameVersion] = []
    @State private var showEditSheet = false
    @State private var editingBundleItem: CollectionItem?
    @State private var bundleDetailTarget: BundleDetailTarget?
    @State private var selectedItemForPurchase: BuylistItem?
    @State private var selectedItemForSellList: CollectionItem?
    @State private var selectedSellListItem: SellListItem?
    @State private var selectedTab: CollectionTab = .collection
    @AppStorage("collection_showStats") private var showCollectionStats = true
    @AppStorage("buylist_showStats") private var showBuylistStats = true
    @AppStorage("sellList_showStats") private var showSellListStats = true

    private let collectionTabs: [InlineTab<CollectionTab>] = [
        InlineTab(title: "Collection", icon: "archivebox.fill", value: .collection),
        InlineTab(title: "Buylist", icon: "cart.fill", value: .buylist),
        InlineTab(title: "Sell List", icon: "tag.fill", value: .sellList)
    ]

    private func handleEditCollectionItem(_ item: CollectionItem) {
        if item.isBundle {
            editingBundleItem = item
        } else if let gameId = item.gameId {
            editingItem = item
            Task {
                await fetchVersionsForGame(gameId: gameId)
                showEditSheet = true
            }
        }
    }

    // scrollPosition(id:) needs an optional binding; it reports nil mid-swipe,
    // which must not clear the selected tab.
    private var pagedTabSelection: Binding<CollectionTab?> {
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
            if !authManager.isSignedIn {
                signInPrompt
            } else {
                    // Tab content — a paging ScrollView instead of TabView(.page):
                    // the UIKit-backed pager re-applies the window's bottom safe area
                    // inside each page, keeping content from reaching the screen bottom.
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 0) {
                            collectionContent
                                .containerRelativeFrame(.horizontal)
                                .id(CollectionTab.collection)

                            buylistContent
                                .containerRelativeFrame(.horizontal)
                                .id(CollectionTab.buylist)

                            sellListContent
                                .containerRelativeFrame(.horizontal)
                                .id(CollectionTab.sellList)
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollIndicators(.hidden)
                    .scrollPosition(id: pagedTabSelection)
                // Extend under the floating tab bar so page content can scroll beneath it.
                .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .navigationBar(title: "Collection")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if authManager.isSignedIn {
                    InlineTabPicker(selectedTab: $selectedTab, tabs: collectionTabs)
                }
            }
        }
        .navigationDestination(item: $bundleDetailTarget) { target in
            BundleDetailView(bundleId: target.id)
        }
        .sheet(isPresented: $showAuth) {
            AuthView()
        }
        .sheet(isPresented: $showEditSheet) {
            if let item = editingItem, let gameId = item.gameId {
                AddToCollectionSheet(
                    gameId: gameId,
                    gameTitle: item.displayTitle,
                    editingItem: item,
                    versions: editingItemVersions
                ) {
                    Task {
                        await collectionViewModel.fetchCollection()
                    }
                }
            }
        }
        .sheet(item: $editingBundleItem) { item in
            EditBundleItemSheet(item: item) {
                Task {
                    await collectionViewModel.fetchCollection(forceRefresh: true)
                }
            }
        }
        .sheet(item: $selectedItemForPurchase) { item in
            MarkAsPurchasedSheet(item: item) {
                Task {
                    await buylistViewModel.fetchBuylist()
                    await buylistViewModel.fetchStats()
                }
            }
        }
        .sheet(item: $selectedItemForSellList) { item in
            AddToSellListSheet(
                collectionItemId: item.id,
                itemTitle: item.displayTitle
            ) {
                Task {
                    await sellListViewModel.fetchSellList()
                    await sellListViewModel.fetchStats()
                }
            }
        }
        .sheet(item: $selectedSellListItem) { item in
            MarkAsSoldSheet(item: item) {
                Task {
                    await sellListViewModel.fetchSellList()
                    await sellListViewModel.fetchStats()
                    await collectionViewModel.fetchCollection()
                }
            }
        }
        .task {
            if authManager.isSignedIn {
                // Fetch all data once on initial load - ViewModels will use cache and skip if already loaded
                await collectionViewModel.fetchCollection()
                await buylistViewModel.fetchBuylist()
                await buylistViewModel.fetchStats()
                await sellListViewModel.fetchSellList()
                await sellListViewModel.fetchStats()
            }
        }
        .onChange(of: authManager.userId) {
            if authManager.isSignedIn {
                Task {
                    // Force refresh when user changes
                    await collectionViewModel.fetchCollection(forceRefresh: true)
                    await buylistViewModel.fetchBuylist(forceRefresh: true)
                    await buylistViewModel.fetchStats(forceRefresh: true)
                    await sellListViewModel.fetchSellList(forceRefresh: true)
                    await sellListViewModel.fetchStats(forceRefresh: true)
                }
            }
        }
    }

    // MARK: - Sign In Prompt

    private var signInPrompt: some View {
        SignInPrompt(message: "Sign in to view your collection") {
            showAuth = true
        }
    }

    // MARK: - Collection Content

    @ViewBuilder
    private var collectionContent: some View {
        let showLoading = collectionViewModel.isLoading || !collectionViewModel.hasLoadedOnce

        if showLoading {
            CabinetLoadingView("Loading collection...")
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
            CabinetEmptyState(
                title: "Your Collection Is Empty",
                message: "Add physical games and bundles to track your collection"
            )
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

                // Collection grid
                if collectionViewModel.groupByPlatform {
                    CollectionGroupedGrid(
                        groups: collectionViewModel.groupedItems,
                        expandedSections: collectionExpandedSections,
                        onRefresh: {
                            await collectionViewModel.fetchCollection(forceRefresh: true)
                        },
                        onEdit: handleEditCollectionItem,
                        onSell: { item in
                            selectedItemForSellList = item
                        },
                        onDelete: { item in
                            Task {
                                await collectionViewModel.removeFromCollection(id: item.id)
                            }
                        },
                        onDetails: { item in
                            if let bundleId = item.bundleId {
                                bundleDetailTarget = BundleDetailTarget(id: bundleId)
                            }
                        }
                    )
                } else {
                    CollectionFlatGrid(
                        items: collectionViewModel.filteredItems,
                        onRefresh: {
                            await collectionViewModel.fetchCollection(forceRefresh: true)
                        },
                        onEdit: handleEditCollectionItem,
                        onSell: { item in
                            selectedItemForSellList = item
                        },
                        onDelete: { item in
                            Task {
                                await collectionViewModel.removeFromCollection(id: item.id)
                            }
                        },
                        onDetails: { item in
                            if let bundleId = item.bundleId {
                                bundleDetailTarget = BundleDetailTarget(id: bundleId)
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Buylist Content

    @ViewBuilder
    private var buylistContent: some View {
        if buylistViewModel.isLoading {
            CabinetLoadingView("Loading buylist...")
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
            CabinetEmptyState(
                title: "Your Buylist Is Empty",
                message: "Browse games, DLCs, and bundles to add them to your buylist"
            )
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

                // Items grid
                if buylistViewModel.groupByPlatform {
                    BuylistGroupedGrid(
                        groups: buylistViewModel.groupedItems,
                        expandedSections: buylistExpandedSections,
                        onRefresh: {
                            await buylistViewModel.fetchBuylist(forceRefresh: true)
                            await buylistViewModel.fetchStats(forceRefresh: true)
                        },
                        onMarkPurchased: { item in
                            selectedItemForPurchase = item
                        },
                        onDelete: { item in
                            Task {
                                await buylistViewModel.removeFromBuylist(id: item.id)
                            }
                        }
                    )
                } else {
                    BuylistFlatGrid(
                        items: buylistViewModel.filteredItems,
                        onRefresh: {
                            await buylistViewModel.fetchBuylist(forceRefresh: true)
                            await buylistViewModel.fetchStats(forceRefresh: true)
                        },
                        onMarkPurchased: { item in
                            selectedItemForPurchase = item
                        },
                        onDelete: { item in
                            Task {
                                await buylistViewModel.removeFromBuylist(id: item.id)
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Sell List Content

    @ViewBuilder
    private var sellListContent: some View {
        if sellListViewModel.isLoading {
            CabinetLoadingView("Loading sell list...")
        } else if let error = sellListViewModel.errorMessage {
            VStack(spacing: 16) {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                Button("Retry") {
                    Task {
                        await sellListViewModel.fetchSellList()
                        await sellListViewModel.fetchStats()
                    }
                }
            }
        } else if sellListViewModel.sellListItems.isEmpty {
            ContentUnavailableView(
                "Your Sell List Is Empty",
                systemImage: "tag",
                description: Text("Long-press collection items to add them to your sell list")
            )
        } else {
            VStack(spacing: 0) {
                // Stats bar
                if let stats = sellListViewModel.stats {
                    CollapsibleStatsBar(
                        stats: sellListStatItems(from: stats),
                        collapsedSummary: "\(stats.activeCount) for sale · \(String(format: "$%.2f", stats.totalAskingValue))",
                        isExpanded: $showSellListStats
                    )
                }

                // Filter bar
                SellListFilterBar(
                    selectedCondition: $sellListViewModel.selectedCondition,
                    conditionCounts: sellListViewModel.conditionCounts,
                    showSoldItems: $sellListViewModel.showSoldItems,
                    selectedSortOption: $sellListViewModel.selectedSortOption,
                    groupByPlatform: $sellListViewModel.groupByPlatform,
                    onSortChanged: {
                        Task {
                            await sellListViewModel.fetchSellList()
                        }
                    }
                )

                // Items grid
                if sellListViewModel.groupByPlatform {
                    SellListGroupedGrid(
                        groups: sellListViewModel.groupedItems,
                        expandedSections: sellListExpandedSections,
                        onRefresh: {
                            await sellListViewModel.fetchSellList(forceRefresh: true)
                            await sellListViewModel.fetchStats(forceRefresh: true)
                        },
                        onMarkSold: { item in
                            selectedSellListItem = item
                        },
                        onDelete: { item in
                            Task {
                                await sellListViewModel.removeFromSellList(id: item.id)
                            }
                        }
                    )
                } else {
                    SellListFlatGrid(
                        items: sellListViewModel.filteredItems,
                        onRefresh: {
                            await sellListViewModel.fetchSellList(forceRefresh: true)
                            await sellListViewModel.fetchStats(forceRefresh: true)
                        },
                        onMarkSold: { item in
                            selectedSellListItem = item
                        },
                        onDelete: { item in
                            Task {
                                await sellListViewModel.removeFromSellList(id: item.id)
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func collectionStatItems(from stats: CollectionStats) -> [StatItem] {
        var items = [
            StatItem(title: "Total", value: "\(stats.totalItems)", icon: "archivebox.fill", color: Cabinet.Tint.info),
            StatItem(title: "Sealed", value: "\(stats.sealedCount)", icon: "seal.fill", color: Cabinet.Tint.violet),
            StatItem(title: "Complete", value: "\(stats.completeCount)", icon: "checkmark.seal.fill", color: Cabinet.Tint.positive),
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
            StatItem(title: "Total", value: "\(stats.totalItems)", icon: "cart.fill", color: Cabinet.Tint.info),
            StatItem(title: "Games", value: "\(stats.gameCount)", icon: "gamecontroller.fill", color: Cabinet.Tint.info),
            StatItem(title: "Bundles", value: "\(stats.bundleCount)", icon: "shippingbox.fill", color: Cabinet.Tint.warm),
            StatItem(title: "DLCs", value: "\(stats.dlcCount)", icon: "puzzlepiece.extension.fill", color: Cabinet.Tint.violet),
            StatItem(title: "High", value: "\(stats.highPriorityCount)", icon: "exclamationmark.circle.fill", color: Cabinet.Tint.alert),
            StatItem(title: "Est. Total", value: String(format: "$%.2f", stats.totalEstimatedCost), icon: "dollarsign.circle.fill", color: Cabinet.Tint.positive),
        ]
    }

    private func sellListStatItems(from stats: SellListStats) -> [StatItem] {
        [
            StatItem(title: "For Sale", value: "\(stats.activeCount)", icon: "tag.fill", color: Cabinet.Tint.warm),
            StatItem(title: "Sold", value: "\(stats.soldCount)", icon: "checkmark.seal.fill", color: Cabinet.Tint.positive),
            StatItem(title: "Asking", value: String(format: "$%.2f", stats.totalAskingValue), icon: "dollarsign.circle", color: Cabinet.Tint.info),
            StatItem(title: "Revenue", value: String(format: "$%.2f", stats.totalSoldValue), icon: "dollarsign.circle.fill", color: Cabinet.Tint.positive),
        ]
    }

    private func regionColor(for region: GameRegion) -> Color {
        switch region {
        case .NTSC_U: return Cabinet.Tint.info
        case .PAL: return Cabinet.Tint.positive
        case .NTSC_J: return Cabinet.Tint.alert
        case .OTHER: return Cabinet.Tint.muted
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
                digitalOnly
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
        case .HIGH: return Cabinet.Tint.alert
        case .MEDIUM: return Cabinet.Tint.warm
        case .LOW: return Cabinet.Tint.positive
        }
    }

    func itemTypeColor(for itemType: BuylistItemType) -> Color {
        switch itemType {
        case .GAME: return Cabinet.Tint.info
        case .DLC: return Cabinet.Tint.violet
        case .BUNDLE: return Cabinet.Tint.violet
        }
    }
}

// MARK: - Collection Item Row

private struct CollectionItemRow: View {
    let item: CollectionItem

    var body: some View {
        HStack(spacing: 12) {
            CoverImage.gameRow(url: item.displayCoverUrl)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.headline)
                    .lineLimit(2)

                TagRow(spacing: 6) {
                    RegionBadge(region: item.region)

                    if let version = item.gameVersion {
                        Badge(text: version.name, color: Cabinet.Tint.info)
                    }

                    if let conditionText = item.condition.label {
                        Badge(text: conditionText, color: item.condition.badgeColor)
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
        Tag(region.displayName, tint: regionColor)
    }

    var regionColor: Color {
        switch region {
        case .NTSC_U: return Cabinet.Tint.info
        case .PAL: return Cabinet.Tint.positive
        case .NTSC_J: return Cabinet.Tint.alert
        case .OTHER: return Cabinet.Tint.muted
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

// MARK: - Owned Bundle Row

private struct OwnedBundleRow: View {
    let bundle: AppBundle

    var body: some View {
        HStack(spacing: 12) {
            // Cover image
            CachedImageFixed(
                url: bundle.coverUrl,
                width: 60,
                height: 60,
                placeholderIcon: "shippingbox"
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(bundle.name)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    BundleTypeBadge(type: bundle.type)

                    if bundle.gameFamilyCount > 0 {
                        Text("\(bundle.gameFamilyCount) games")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Platform icons
                if !bundle.platforms.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(bundle.platforms.prefix(4)) { platform in
                            PlatformIcon(slug: platform.slug ?? "", size: 16)
                        }
                        if bundle.platforms.count > 4 {
                            Text("+\(bundle.platforms.count - 4)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Sell List Filter Bar

private struct SellListFilterBar: View {
    @Binding var selectedCondition: ItemCondition?
    let conditionCounts: [ItemCondition: Int]
    @Binding var showSoldItems: Bool
    @Binding var selectedSortOption: SellListSortOption
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
                    count: conditionCounts.values.reduce(0, +),
                    isSelected: selectedCondition == nil,
                    color: filterAllColor
                ) {
                    selectedCondition = nil
                }

                ForEach(ItemCondition.allCases, id: \.self) { condition in
                    let count = conditionCounts[condition] ?? 0
                    if count > 0 {
                        FilterPill(
                            title: condition.shortName,
                            count: count,
                            isSelected: selectedCondition == condition,
                            color: conditionColor(for: condition)
                        ) {
                            selectedCondition = condition
                        }
                    }
                }

                Divider().frame(height: 24)

                Button {
                    showSoldItems.toggle()
                } label: {
                    FilterChip(
                        title: "Show Sold",
                        isActive: showSoldItems,
                        activeColor: .green
                    )
                }
            }
        }
    }

    func conditionColor(for condition: ItemCondition) -> Color {
        switch condition {
        case .MINT: return Cabinet.Tint.positive
        case .NEAR_MINT: return Cabinet.Tint.info
        case .VERY_GOOD: return Cabinet.Tint.info
        case .GOOD: return Cabinet.Tint.warm
        case .FAIR: return Cabinet.Tint.alert
        case .POOR: return Cabinet.Tint.muted
        }
    }
}

// MARK: - Sell List Item Row

private struct SellListItemRow: View {
    let item: SellListItem

    var body: some View {
        HStack(spacing: 12) {
            // Cover image
            CachedImageFixed(url: item.displayCoverUrl, width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.headline)
                    .lineLimit(2)

                TagRow(spacing: 6) {
                    // Condition badge
                    ConditionBadge(condition: item.condition)

                    // Status badge
                    if item.status == .SOLD {
                        Badge(text: "Sold", color: Cabinet.Tint.positive)
                    }
                }

                // Price info
                HStack(spacing: 8) {
                    if item.status == .SOLD, let salePrice = item.salePrice {
                        Text(String(format: "$%.2f", salePrice))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    } else if let askingPrice = item.askingPrice {
                        Text(String(format: "$%.2f", askingPrice))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }

                    if item.listingUrl != nil {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            if let platform = item.displayPlatform, let slug = platform.slug {
                PlatformIcon(slug: slug, size: 24)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(item.status == .SOLD ? 0.7 : 1.0)
    }
}

// MARK: - Condition Badge

private struct ConditionBadge: View {
    let condition: ItemCondition

    var body: some View {
        Tag(condition.shortName, tint: conditionColor)
    }

    var conditionColor: Color {
        switch condition {
        case .MINT: return Cabinet.Tint.positive
        case .NEAR_MINT: return Cabinet.Tint.info
        case .VERY_GOOD: return Cabinet.Tint.info
        case .GOOD: return Cabinet.Tint.warm
        case .FAIR: return Cabinet.Tint.alert
        case .POOR: return Cabinet.Tint.muted
        }
    }
}

// MARK: - Collection Grid Components

struct BundleDetailTarget: Identifiable, Hashable {
    let id: String
}

private struct CollectionGroupedGrid: View {
    let groups: [(platform: Platform?, items: [CollectionItem])]
    let expandedSections: ExpandedSectionsState
    let onRefresh: () async -> Void
    let onEdit: (CollectionItem) -> Void
    let onSell: (CollectionItem) -> Void
    let onDelete: (CollectionItem) -> Void
    let onDetails: (CollectionItem) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    let sectionId = group.platform?.id ?? "other"

                    Section {
                        if expandedSections.isExpanded(sectionId) {
                            CollectionItemsGrid(
                                items: group.items,
                                onEdit: onEdit,
                                onSell: onSell,
                                onDelete: onDelete,
                                onDetails: onDetails
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
        .refreshable {
            await onRefresh()
        }
        .onAppear {
            let ids = groups.map { $0.platform?.id ?? "other" }
            expandedSections.expandAll(ids)
        }
    }
}

private struct CollectionFlatGrid: View {
    let items: [CollectionItem]
    let onRefresh: () async -> Void
    let onEdit: (CollectionItem) -> Void
    let onSell: (CollectionItem) -> Void
    let onDelete: (CollectionItem) -> Void
    let onDetails: (CollectionItem) -> Void

    var body: some View {
        ScrollView {
            CollectionItemsGrid(
                items: items,
                onEdit: onEdit,
                onSell: onSell,
                onDelete: onDelete,
                onDetails: onDetails
            )
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .contentMargins(.bottom, 100, for: .scrollContent)
        .refreshable {
            await onRefresh()
        }
    }
}

/// Grid of collection items where bundle cells expand in place to reveal the
/// games stacked inside them.
private struct CollectionItemsGrid: View {
    let items: [CollectionItem]
    let onEdit: (CollectionItem) -> Void
    let onSell: (CollectionItem) -> Void
    let onDelete: (CollectionItem) -> Void
    let onDetails: (CollectionItem) -> Void

    @State private var expandedBundleIds: Set<String> = []
    @Namespace private var zoomNamespace

    private let columns = GameCoverGridLayout.columns()

    private enum GridCell: Identifiable {
        case item(CollectionItem)
        case bundleGame(BundleGameFamily, parentId: String)

        var id: String {
            switch self {
            case .item(let item): return "item-\(item.id)"
            case .bundleGame(let family, let parentId): return "family-\(parentId)-\(family.id)"
            }
        }
    }

    private var cells: [GridCell] {
        var cells: [GridCell] = []
        for item in items {
            cells.append(.item(item))
            if item.isBundle, expandedBundleIds.contains(item.id) {
                for family in item.bundle?.gameFamilies ?? [] {
                    cells.append(.bundleGame(family, parentId: item.id))
                }
            }
        }
        return cells
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(cells) { cell in
                switch cell {
                case .item(let item):
                    if item.isBundle {
                        CollectionBundleCell(
                            item: item,
                            isExpanded: expandedBundleIds.contains(item.id),
                            onToggle: {
                                Motion.animate(.snappy) {
                                    if expandedBundleIds.contains(item.id) {
                                        expandedBundleIds.remove(item.id)
                                    } else {
                                        expandedBundleIds.insert(item.id)
                                    }
                                }
                            },
                            onEdit: { onEdit(item) },
                            onSell: { onSell(item) },
                            onDelete: { onDelete(item) },
                            onDetails: { onDetails(item) }
                        )
                    } else {
                        CollectionGridCell(
                            item: item,
                            onEdit: { onEdit(item) },
                            onSell: { onSell(item) },
                            onDelete: { onDelete(item) }
                        )
                    }
                case .bundleGame(let family, _):
                    NavigationLink(
                        destination: GameFamilyRouter(title: family.title)
                            .navigationTransition(.zoom(sourceID: cell.id, in: zoomNamespace))
                    ) {
                        GameCoverCell(coverUrl: family.coverUrl, title: family.title) {
                            // Marks the cell as coming from an expanded bundle
                            GroupIndicatorOverlay()
                        }
                    }
                    .matchedTransitionSource(id: cell.id, in: zoomNamespace)
                    .buttonStyle(.plain)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: expandedBundleIds)
    }
}

/// Bundle collection item rendered as a stacked pile of games. Tapping fans
/// the pile open; the context menu carries the item actions.
private struct CollectionBundleCell: View {
    let item: CollectionItem
    let isExpanded: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onSell: () -> Void
    let onDelete: () -> Void
    let onDetails: () -> Void

    private var gameCount: Int { item.bundle?.gameFamilies?.count ?? 0 }

    var body: some View {
        Button(action: onToggle) {
            ZStack {
                // Cards peeking out behind the cover hint at the games inside
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

                GameCoverCell(coverUrl: item.displayCoverUrl, title: item.displayTitle) {
                    RegionOverlayBadge(region: item.region)

                    VStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 10))
                            if gameCount > 0 {
                                Text("\(gameCount)")
                                    .font(.system(size: 10, weight: .bold))
                            }
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
        .contextMenu {
            Button {
                onDetails()
            } label: {
                Label("Bundle Details", systemImage: "shippingbox")
            }

            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
                onSell()
            } label: {
                Label("Add to Sell List", systemImage: "tag")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Remove from Collection", systemImage: "trash")
            }
        }
    }
}

/// Region, condition, and notes editor for bundle collection items. Reuses
/// AddToCollectionViewModel's updateCollectionItem mutation.
private struct EditBundleItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddToCollectionViewModel()
    let item: CollectionItem
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Region", selection: $viewModel.region) {
                        ForEach(GameRegion.allCases, id: \.self) { region in
                            Text(region.displayName).tag(region)
                        }
                    }
                    Toggle("Digital Copy", isOn: $viewModel.isDigital)
                }

                Section {
                    Toggle("Has Cartridge/Disc", isOn: $viewModel.hasDisc)
                        .disabled(viewModel.isDigital)
                    Toggle("Has Box", isOn: $viewModel.hasBox)
                        .disabled(viewModel.isDigital)
                    Toggle("Has Manual", isOn: $viewModel.hasManual)
                        .disabled(viewModel.isDigital)
                    Toggle("Has Extras", isOn: $viewModel.hasExtras)
                        .disabled(viewModel.isDigital)
                    Toggle("Sealed", isOn: $viewModel.isSealed)
                        .disabled(viewModel.isDigital)
                } header: {
                    Text("Physical Condition")
                }

                Section {
                    TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Section {
                    Button {
                        Task {
                            if await viewModel.updateCollectionItem(id: item.id) {
                                Haptics.success()
                                onSave()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Save Changes")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle(item.displayTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.region = item.region
            viewModel.platformId = item.platform?.id
            viewModel.isDigital = item.isDigital ?? false
            viewModel.hasDisc = item.hasDisc
            viewModel.hasBox = item.hasBox
            viewModel.hasManual = item.hasManual
            viewModel.hasExtras = item.hasExtras
            viewModel.isSealed = item.isSealed
            viewModel.notes = item.notes ?? ""
        }
    }
}

private struct CollectionGridCell: View {
    let item: CollectionItem
    let onEdit: () -> Void
    let onSell: () -> Void
    let onDelete: () -> Void

    @Namespace private var zoomNamespace

    var body: some View {
        NavigationLink(
            destination: GameDetailView(gameId: item.gameId ?? "")
                .navigationTransition(.zoom(sourceID: item.id, in: zoomNamespace))
        ) {
            GameCoverCell(coverUrl: item.displayCoverUrl, title: item.displayTitle) {
                // Region badge (top-left)
                RegionOverlayBadge(region: item.region)

                // Condition tag + component icons (bottom)
                CollectionConditionOverlay(
                    condition: item.condition,
                    hasDisc: item.hasDisc,
                    hasBox: item.hasBox,
                    hasManual: item.hasManual
                )
            }
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button {
                    onSell()
                } label: {
                    Label("Add to Sell List", systemImage: "tag")
                }

                Divider()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Remove from Collection", systemImage: "trash")
                }
            }
        }
        .matchedTransitionSource(id: item.id, in: zoomNamespace)
    }
}

// MARK: - Buylist Grid Components

private struct BuylistGroupedGrid: View {
    let groups: [(platform: BuylistPlatform?, items: [BuylistItem])]
    let expandedSections: ExpandedSectionsState
    let onRefresh: () async -> Void
    let onMarkPurchased: (BuylistItem) -> Void
    let onDelete: (BuylistItem) -> Void

    private let columns = GameCoverGridLayout.columns()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    let sectionId = "buylist_\(group.platform?.id ?? "other")"

                    Section {
                        if expandedSections.isExpanded(sectionId) {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(group.items) { item in
                                    BuylistGridCell(
                                        item: item,
                                        onMarkPurchased: { onMarkPurchased(item) },
                                        onDelete: { onDelete(item) }
                                    )
                                }
                            }
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
        .refreshable {
            await onRefresh()
        }
        .onAppear {
            let ids = groups.map { "buylist_\($0.platform?.id ?? "other")" }
            expandedSections.expandAll(ids)
        }
    }
}

private struct BuylistFlatGrid: View {
    let items: [BuylistItem]
    let onRefresh: () async -> Void
    let onMarkPurchased: (BuylistItem) -> Void
    let onDelete: (BuylistItem) -> Void

    private let columns = GameCoverGridLayout.columns()

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    BuylistGridCell(
                        item: item,
                        onMarkPurchased: { onMarkPurchased(item) },
                        onDelete: { onDelete(item) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .contentMargins(.bottom, 100, for: .scrollContent)
        .refreshable {
            await onRefresh()
        }
    }
}

private struct BuylistGridCell: View {
    let item: BuylistItem
    let onMarkPurchased: () -> Void
    let onDelete: () -> Void

    @ViewBuilder
    private var destination: some View {
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

    var body: some View {
        NavigationLink(destination: destination) {
            GameCoverCell(coverUrl: item.displayCoverUrl, title: item.displayTitle) {
                // Item type badge (top-left)
                ItemTypeOverlayBadge(itemType: item.itemType)

                // Priority badge (top-right)
                PriorityOverlayBadge(priority: item.priority)

                // Price overlay (bottom-left) if available
                if let price = item.estimatedPrice {
                    PriceOverlay(price: price)
                }
            }
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    onMarkPurchased()
                } label: {
                    Label("Mark as Purchased", systemImage: "checkmark.circle")
                }

                Divider()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Remove from Buylist", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Sell List Grid Components

private struct SellListGroupedGrid: View {
    let groups: [(platform: SellListPlatform?, items: [SellListItem])]
    let expandedSections: ExpandedSectionsState
    let onRefresh: () async -> Void
    let onMarkSold: (SellListItem) -> Void
    let onDelete: (SellListItem) -> Void

    private let columns = GameCoverGridLayout.columns()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    let sectionId = "sell_\(group.platform?.id ?? "other")"

                    Section {
                        if expandedSections.isExpanded(sectionId) {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(group.items) { item in
                                    SellListGridCell(
                                        item: item,
                                        onMarkSold: { onMarkSold(item) },
                                        onDelete: { onDelete(item) }
                                    )
                                }
                            }
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
        .refreshable {
            await onRefresh()
        }
        .onAppear {
            let ids = groups.map { "sell_\($0.platform?.id ?? "other")" }
            expandedSections.expandAll(ids)
        }
    }
}

private struct SellListFlatGrid: View {
    let items: [SellListItem]
    let onRefresh: () async -> Void
    let onMarkSold: (SellListItem) -> Void
    let onDelete: (SellListItem) -> Void

    private let columns = GameCoverGridLayout.columns()

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    SellListGridCell(
                        item: item,
                        onMarkSold: { onMarkSold(item) },
                        onDelete: { onDelete(item) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .contentMargins(.bottom, 100, for: .scrollContent)
        .refreshable {
            await onRefresh()
        }
    }
}

private struct SellListGridCell: View {
    let item: SellListItem
    let onMarkSold: () -> Void
    let onDelete: () -> Void

    var body: some View {
        GameCoverCell(coverUrl: item.displayCoverUrl, title: item.displayTitle) {
            // Condition badge (top-right)
            ConditionOverlayBadge(condition: item.condition)

            // Price overlay (bottom-left) if not sold
            if item.status != .SOLD, let price = item.askingPrice {
                PriceOverlay(price: price)
            }

            // Sold overlay (bottom) if sold
            SoldStatusOverlay(isSold: item.status == .SOLD, price: item.salePrice)
        }
        .contentShape(Rectangle())
        .contextMenu {
            if item.status == .ACTIVE {
                Button {
                    onMarkSold()
                } label: {
                    Label("Mark as Sold", systemImage: "checkmark.circle")
                }

                Divider()

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Remove from Sell List", systemImage: "trash")
                }
            }
        }
        .opacity(item.status == .SOLD ? 0.7 : 1.0)
    }
}

