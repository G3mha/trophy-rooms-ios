import SwiftUI
import ClerkKit

private enum CollectionTab: Int, Hashable {
    case collection = 0
    case buylist = 1
    case sellList = 2
}

struct CollectionView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var collectionViewModel = CollectionViewModel()
    @StateObject private var buylistViewModel = BuylistViewModel()
    @StateObject private var sellListViewModel = SellListViewModel()
    @StateObject private var expandedSections = ExpandedSectionsState()
    @State private var showAuth = false
    @State private var editingItem: CollectionItem?
    @State private var editingItemVersions: [GameVersion] = []
    @State private var showEditSheet = false
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

                        sellListContent
                            .tag(CollectionTab.sellList)
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
                itemTitle: item.game.title
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
            if clerk.user != nil {
                if !collectionViewModel.hasLoadedOnce {
                    await collectionViewModel.fetchCollection()
                }
                await buylistViewModel.fetchBuylist()
                await buylistViewModel.fetchStats()
                await sellListViewModel.fetchSellList()
                await sellListViewModel.fetchStats()
            }
        }
        .onChange(of: clerk.user?.id) {
            if clerk.user != nil {
                Task {
                    await collectionViewModel.fetchCollection()
                    await buylistViewModel.fetchBuylist()
                    await buylistViewModel.fetchStats()
                    await sellListViewModel.fetchSellList()
                    await sellListViewModel.fetchStats()
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
        } else if collectionViewModel.collectionItems.isEmpty && collectionViewModel.ownedBundles.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "archivebox")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Your collection is empty")
                    .font(.headline)
                Text("Add physical games and bundles to track your collection")
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

                // Collection grid
                if collectionViewModel.groupByPlatform {
                    CollectionGroupedGrid(
                        groups: collectionViewModel.groupedItems,
                        ownedBundles: collectionViewModel.ownedBundles,
                        expandedSections: expandedSections,
                        onEdit: { item in
                            editingItem = item
                            Task {
                                await fetchVersionsForGame(gameId: item.gameId)
                                showEditSheet = true
                            }
                        },
                        onSell: { item in
                            selectedItemForSellList = item
                        },
                        onDelete: { item in
                            Task {
                                await collectionViewModel.removeFromCollection(id: item.id)
                            }
                        }
                    )
                } else {
                    CollectionFlatGrid(
                        items: collectionViewModel.filteredItems,
                        ownedBundles: collectionViewModel.ownedBundles,
                        onEdit: { item in
                            editingItem = item
                            Task {
                                await fetchVersionsForGame(gameId: item.gameId)
                                showEditSheet = true
                            }
                        },
                        onSell: { item in
                            selectedItemForSellList = item
                        },
                        onDelete: { item in
                            Task {
                                await collectionViewModel.removeFromCollection(id: item.id)
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

                // Items grid
                if buylistViewModel.groupByPlatform {
                    BuylistGroupedGrid(
                        groups: buylistViewModel.groupedItems,
                        expandedSections: expandedSections,
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
            ProgressView("Loading sell list...")
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
            VStack(spacing: 16) {
                Image(systemName: "tag")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)
                Text("Your sell list is empty")
                    .font(.headline)
                Text("Swipe left on collection items to add them to your sell list")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
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
                        expandedSections: expandedSections,
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

    private func sellListStatItems(from stats: SellListStats) -> [StatItem] {
        [
            StatItem(title: "For Sale", value: "\(stats.activeCount)", icon: "tag.fill", color: .orange),
            StatItem(title: "Sold", value: "\(stats.soldCount)", icon: "checkmark.seal.fill", color: .green),
            StatItem(title: "Asking", value: String(format: "$%.2f", stats.totalAskingValue), icon: "dollarsign.circle", color: .blue),
            StatItem(title: "Revenue", value: String(format: "$%.2f", stats.totalSoldValue), icon: "dollarsign.circle.fill", color: .green),
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

// MARK: - Owned Bundle Row

private struct OwnedBundleRow: View {
    let bundle: AppBundle

    var body: some View {
        HStack(spacing: 12) {
            // Cover image
            if let coverUrl = bundle.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "shippingbox")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
            }

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
        case .MINT: return .green
        case .NEAR_MINT: return .teal
        case .VERY_GOOD: return .blue
        case .GOOD: return .orange
        case .FAIR: return .red
        case .POOR: return .gray
        }
    }
}

// MARK: - Sell List Item Row

private struct SellListItemRow: View {
    let item: SellListItem

    var body: some View {
        HStack(spacing: 12) {
            // Cover image
            if let coverUrl = item.displayCoverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "gamecontroller")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    // Condition badge
                    ConditionBadge(condition: item.condition)

                    // Status badge
                    if item.status == .SOLD {
                        Badge(text: "Sold", color: .green)
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
        Text(condition.shortName)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(conditionColor.opacity(0.15))
            .foregroundColor(conditionColor)
            .cornerRadius(4)
    }

    var conditionColor: Color {
        switch condition {
        case .MINT: return .green
        case .NEAR_MINT: return .teal
        case .VERY_GOOD: return .blue
        case .GOOD: return .orange
        case .FAIR: return .red
        case .POOR: return .gray
        }
    }
}

// MARK: - Collection Grid Components

private struct CollectionGroupedGrid: View {
    let groups: [(platform: Platform?, items: [CollectionItem])]
    let ownedBundles: [AppBundle]
    let expandedSections: ExpandedSectionsState
    let onEdit: (CollectionItem) -> Void
    let onSell: (CollectionItem) -> Void
    let onDelete: (CollectionItem) -> Void

    private let columns = GameCoverGridLayout.columns(count: 3)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                // Owned Bundles section
                if !ownedBundles.isEmpty {
                    Section {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(ownedBundles) { bundle in
                                NavigationLink(destination: BundleDetailView(bundleId: bundle.id)) {
                                    GameCoverCell(coverUrl: bundle.coverUrl, title: bundle.name) {
                                        // Owned indicator
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white)
                                                    .background(Circle().fill(Color.green).frame(width: 18, height: 18))
                                                    .padding(4)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    } header: {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                            Text("Bundles (\(ownedBundles.count))")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                    }
                }

                // Game groups
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    let sectionId = group.platform?.id ?? "other"

                    Section {
                        if expandedSections.isExpanded(sectionId) {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(group.items) { item in
                                    CollectionGridCell(
                                        item: item,
                                        onEdit: { onEdit(item) },
                                        onSell: { onSell(item) },
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
        .onAppear {
            let ids = groups.map { $0.platform?.id ?? "other" }
            expandedSections.expandAll(ids)
        }
    }
}

private struct CollectionFlatGrid: View {
    let items: [CollectionItem]
    let ownedBundles: [AppBundle]
    let onEdit: (CollectionItem) -> Void
    let onSell: (CollectionItem) -> Void
    let onDelete: (CollectionItem) -> Void

    private let columns = GameCoverGridLayout.columns(count: 3)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Owned Bundles section
                if !ownedBundles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "shippingbox.fill")
                            Text("Bundles (\(ownedBundles.count))")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.horizontal)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(ownedBundles) { bundle in
                                NavigationLink(destination: BundleDetailView(bundleId: bundle.id)) {
                                    GameCoverCell(coverUrl: bundle.coverUrl, title: bundle.name) {
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white)
                                                    .background(Circle().fill(Color.green).frame(width: 18, height: 18))
                                                    .padding(4)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }

                // Games grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        CollectionGridCell(
                            item: item,
                            onEdit: { onEdit(item) },
                            onSell: { onSell(item) },
                            onDelete: { onDelete(item) }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
        }
    }
}

private struct CollectionGridCell: View {
    let item: CollectionItem
    let onEdit: () -> Void
    let onSell: () -> Void
    let onDelete: () -> Void

    var body: some View {
        NavigationLink(destination: GameDetailView(gameId: item.gameId)) {
            GameCoverCell(coverUrl: item.game.coverUrl, title: item.game.title) {
                // Region badge (top-left)
                RegionOverlayBadge(region: item.region)

                // Condition indicators (bottom)
                CollectionConditionOverlay(
                    isSealed: item.isSealed,
                    isComplete: item.isComplete,
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
    }
}

// MARK: - Buylist Grid Components

private struct BuylistGroupedGrid: View {
    let groups: [(platform: BuylistPlatform?, items: [BuylistItem])]
    let expandedSections: ExpandedSectionsState
    let onMarkPurchased: (BuylistItem) -> Void
    let onDelete: (BuylistItem) -> Void

    private let columns = GameCoverGridLayout.columns(count: 3)

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
        .onAppear {
            let ids = groups.map { "buylist_\($0.platform?.id ?? "other")" }
            expandedSections.expandAll(ids)
        }
    }
}

private struct BuylistFlatGrid: View {
    let items: [BuylistItem]
    let onMarkPurchased: (BuylistItem) -> Void
    let onDelete: (BuylistItem) -> Void

    private let columns = GameCoverGridLayout.columns(count: 3)

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
    let onMarkSold: (SellListItem) -> Void
    let onDelete: (SellListItem) -> Void

    private let columns = GameCoverGridLayout.columns(count: 3)

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
        .onAppear {
            let ids = groups.map { "sell_\($0.platform?.id ?? "other")" }
            expandedSections.expandAll(ids)
        }
    }
}

private struct SellListFlatGrid: View {
    let items: [SellListItem]
    let onMarkSold: (SellListItem) -> Void
    let onDelete: (SellListItem) -> Void

    private let columns = GameCoverGridLayout.columns(count: 3)

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

