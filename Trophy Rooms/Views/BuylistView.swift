import SwiftUI
import ClerkKit

struct BuylistView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = BuylistViewModel()
    @StateObject private var expandedSections = ExpandedSectionsState()
    @State private var showAuth = false
    @State private var showPurchasedSheet = false
    @State private var selectedItemForPurchase: BuylistItem?
    @State private var showStats = true

    var body: some View {
        Group {
            if clerk.user == nil {
                VStack(spacing: 16) {
                    Image(systemName: "cart")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Sign in to view your buylist")
                        .font(.headline)
                    Button("Sign In") {
                        showAuth = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.isLoading {
                ProgressView("Loading buylist...")
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await viewModel.fetchBuylist()
                            await viewModel.fetchStats()
                        }
                    }
                }
            } else if viewModel.buylistItems.isEmpty {
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
                    if let stats = viewModel.stats {
                        CollapsibleStatsBar(
                            stats: buylistStatItems(from: stats),
                            collapsedSummary: "\(stats.totalItems) items · \(String(format: "$%.2f", stats.totalEstimatedCost))",
                            isExpanded: $showStats
                        )
                    }

                    // Filter pills
                    BuylistFilterView(
                        selectedPriority: $viewModel.selectedPriority,
                        priorityCounts: viewModel.priorityCounts,
                        selectedItemType: $viewModel.selectedItemType,
                        itemTypeCounts: viewModel.itemTypeCounts,
                        selectedSortOption: $viewModel.selectedSortOption,
                        groupByPlatform: $viewModel.groupByPlatform,
                        onSortChanged: {
                            Task {
                                await viewModel.fetchBuylist()
                            }
                        }
                    )

                    // Items list
                    List {
                        if viewModel.groupByPlatform {
                            ForEach(Array(viewModel.groupedItems.enumerated()), id: \.offset) { _, group in
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
                                                        await viewModel.removeFromBuylist(id: item.id)
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
                                // Expand all sections by default
                                let ids = viewModel.groupedItems.map { $0.platform?.id ?? "other" }
                                expandedSections.expandAll(ids)
                            }
                        } else {
                            ForEach(viewModel.filteredItems) { item in
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
                                            await viewModel.removeFromBuylist(id: item.id)
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
        .navigationBar(
            title: "Buylist",
            shareURL: clerk.user.map { URL(string: "https://trophyrooms.app/users/\($0.id)/buylist")! }
        )
        .sheet(isPresented: $showAuth) {
            AuthView()
        }
        .sheet(isPresented: $showPurchasedSheet) {
            if let item = selectedItemForPurchase {
                MarkAsPurchasedSheet(item: item) {
                    Task {
                        await viewModel.fetchBuylist()
                        await viewModel.fetchStats()
                    }
                }
            }
        }
        .task {
            if clerk.user != nil {
                await viewModel.fetchBuylist()
                await viewModel.fetchStats()
            }
        }
        .onChange(of: clerk.user?.id) {
            if clerk.user != nil {
                Task {
                    await viewModel.fetchBuylist()
                    await viewModel.fetchStats()
                }
            }
        }
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
            // TODO: Add DLCDetailView when available
            Text("DLC: \(item.displayTitle)")
        case .BUNDLE:
            if let bundleId = item.bundleId {
                BundleDetailView(bundleId: bundleId)
            } else {
                Text("Bundle not found")
            }
        }
    }

}

// MARK: - Filter View

private struct BuylistFilterView: View {
    @Binding var selectedPriority: BuylistPriority?
    let priorityCounts: [BuylistPriority: Int]
    @Binding var selectedItemType: BuylistItemType?
    let itemTypeCounts: [BuylistItemType: Int]
    @Binding var selectedSortOption: BuylistSortOption
    @Binding var groupByPlatform: Bool
    let onSortChanged: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Sort and group controls
            SortGroupControls(
                selectedSortOption: $selectedSortOption,
                groupByPlatform: $groupByPlatform,
                onSortChanged: onSortChanged
            )

            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // All filter
                    FilterPill(
                        title: "All",
                        count: priorityCounts.values.reduce(0, +),
                        isSelected: selectedPriority == nil && selectedItemType == nil,
                        color: Color(.darkGray)
                    ) {
                        selectedPriority = nil
                        selectedItemType = nil
                    }

                    // Priority filters
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

                    // Item type filters
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
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .background(Color(.systemBackground))
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

private struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? color : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Item Row

private struct BuylistItemRow: View {
    let item: BuylistItem
    var showPlatform: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            CoverImage(
                url: item.displayCoverUrl,
                width: 60,
                height: 80,
                placeholderIcon: item.itemType.iconName
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayTitle)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    PriorityBadge(priority: item.priority)
                    ItemTypeBadge(itemType: item.itemType)
                }

                if let price = item.estimatedPrice {
                    Text(String(format: "$%.2f", price))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Text("Added \(formattedDate(item.addedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Platform icon on the right
            if showPlatform, let platform = item.displayPlatform, let slug = platform.slug {
                PlatformIcon(slug: slug, size: 24)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        return dateString
    }
}

// MARK: - Badges

struct PriorityBadge: View {
    let priority: BuylistPriority

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priority.iconName)
                .font(.caption2)
            Text(priority.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priorityColor.opacity(0.15))
        .foregroundColor(priorityColor)
        .cornerRadius(8)
    }

    var priorityColor: Color {
        switch priority {
        case .HIGH: return .red
        case .MEDIUM: return .orange
        case .LOW: return .green
        }
    }
}

struct ItemTypeBadge: View {
    let itemType: BuylistItemType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: itemType.iconName)
                .font(.caption2)
            Text(itemType.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(itemTypeColor.opacity(0.15))
        .foregroundColor(itemTypeColor)
        .cornerRadius(8)
    }

    var itemTypeColor: Color {
        switch itemType {
        case .GAME: return .blue
        case .DLC: return .purple
        case .BUNDLE: return .pink
        }
    }
}
