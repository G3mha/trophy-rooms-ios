import SwiftUI
import Combine

// MARK: - Game Cover Cell

/// A reusable game cover cell with optional overlay badges and context menu support
struct GameCoverCell<Overlay: View>: View {
    let coverUrl: String?
    let title: String
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat
    let overlay: () -> Overlay

    init(
        coverUrl: String?,
        title: String,
        aspectRatio: CGFloat = 3/4,
        cornerRadius: CGFloat = 8,
        @ViewBuilder overlay: @escaping () -> Overlay = { EmptyView() }
    ) {
        self.coverUrl = coverUrl
        self.title = title
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        self.overlay = overlay
    }

    var body: some View {
        VStack(spacing: 0) {
            if let coverUrl = coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(aspectRatio, contentMode: .fill)
                    case .failure:
                        GameCoverPlaceholder(title: title)
                    @unknown default:
                        GameCoverPlaceholder(title: title)
                    }
                }
            } else {
                GameCoverPlaceholder(title: title)
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .cornerRadius(cornerRadius)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(overlay())
    }
}

// MARK: - Game Cover Placeholder

struct GameCoverPlaceholder: View {
    let title: String
    var icon: String = "gamecontroller"

    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text(title)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 4)
                }
            )
    }
}

// MARK: - Overlay Badges

/// Group indicator badge (top-right corner)
struct GroupIndicatorOverlay: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: "square.stack.fill")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
                    .padding(4)
            }
            Spacer()
        }
    }
}

/// Status overlay badge for library items (top-right corner)
struct StatusOverlayBadge: View {
    let status: GameStatus

    var body: some View {
        VStack {
            HStack {
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: status.iconName)
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(statusColor)
                .cornerRadius(4)
                .padding(4)
            }
            Spacer()
        }
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

/// Region overlay badge for collection items (top-left corner)
struct RegionOverlayBadge: View {
    let region: GameRegion

    var body: some View {
        VStack {
            HStack {
                Text(region.shortName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(regionColor)
                    .cornerRadius(4)
                    .padding(4)
                Spacer()
            }
            Spacer()
        }
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

/// Condition indicators overlay for collection items (bottom)
struct CollectionConditionOverlay: View {
    let isSealed: Bool
    let isComplete: Bool
    let hasDisc: Bool
    let hasBox: Bool
    let hasManual: Bool

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 2) {
                if isSealed {
                    conditionIcon("seal.fill", color: .purple)
                } else {
                    if hasDisc { conditionIcon("opticaldisc", color: .white) }
                    if hasBox { conditionIcon("shippingbox.fill", color: .white) }
                    if hasManual { conditionIcon("book.closed.fill", color: .white) }
                }
                if isComplete && !isSealed {
                    conditionIcon("checkmark.circle.fill", color: .green)
                }
            }
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

    private func conditionIcon(_ name: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 10))
            .foregroundColor(color)
    }
}

/// Priority overlay badge for buylist items (top-right corner)
struct PriorityOverlayBadge: View {
    let priority: BuylistPriority

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(priorityMarker)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(priorityColor)
                    .cornerRadius(4)
                    .padding(4)
            }
            Spacer()
        }
    }

    var priorityMarker: String {
        switch priority {
        case .HIGH: return "!!!"
        case .MEDIUM: return "!!"
        case .LOW: return "!"
        }
    }

    var priorityColor: Color {
        switch priority {
        case .HIGH: return .red
        case .MEDIUM: return .orange
        case .LOW: return .green
        }
    }
}

/// Item type overlay badge for buylist items (top-left corner)
struct ItemTypeOverlayBadge: View {
    let itemType: BuylistItemType

    var body: some View {
        VStack {
            HStack {
                Image(systemName: itemType.iconName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(5)
                    .background(itemTypeColor)
                    .cornerRadius(4)
                    .padding(4)
                Spacer()
            }
            Spacer()
        }
    }

    var itemTypeColor: Color {
        switch itemType {
        case .GAME: return .blue
        case .DLC: return .purple
        case .BUNDLE: return .pink
        }
    }
}

/// Condition overlay badge for sell list items (top-right corner)
struct ConditionOverlayBadge: View {
    let condition: ItemCondition

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text(condition.shortName)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(conditionColor)
                    .cornerRadius(4)
                    .padding(4)
            }
            Spacer()
        }
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

/// Sold status overlay for sell list items (bottom)
struct SoldStatusOverlay: View {
    let isSold: Bool
    let price: Double?

    var body: some View {
        if isSold {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("SOLD")
                            .font(.system(size: 8, weight: .bold))
                        if let price = price {
                            Text(String(format: "$%.0f", price))
                                .font(.system(size: 9, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    Spacer()
                }
                .background(
                    LinearGradient(
                        colors: [.clear, .green.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }
}

/// Price overlay for sell list items (bottom-left)
struct PriceOverlay: View {
    let price: Double

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text(String(format: "$%.0f", price))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.9))
                    .cornerRadius(4)
                    .padding(4)
                Spacer()
            }
        }
    }
}

// MARK: - Game Cover with Context Menu

/// A game cover cell with built-in context menu support
struct GameCoverWithContextMenu<Overlay: View>: View {
    let gameId: String
    let gameTitle: String
    let coverUrl: String?
    let platformId: String?
    let overlay: () -> Overlay

    init(
        gameId: String,
        gameTitle: String,
        coverUrl: String?,
        platformId: String? = nil,
        @ViewBuilder overlay: @escaping () -> Overlay = { EmptyView() }
    ) {
        self.gameId = gameId
        self.gameTitle = gameTitle
        self.coverUrl = coverUrl
        self.platformId = platformId
        self.overlay = overlay
    }

    var body: some View {
        SimpleGameContextMenu(
            gameId: gameId,
            gameTitle: gameTitle,
            platformId: platformId
        ) {
            GameCoverCell(coverUrl: coverUrl, title: gameTitle, overlay: overlay)
        }
    }
}

// MARK: - Game Cover Grid

/// A reusable grid component for displaying game covers
struct GameCoverGridLayout: View {
    let columns: [GridItem]

    init(columnCount: Int = 3, spacing: CGFloat = 12) {
        self.columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount)
    }

    var body: some View {
        // This is just a configuration holder - use the static method
        EmptyView()
    }

    static func columns(count: Int = 3, spacing: CGFloat = 12) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }
}

// MARK: - Platform Section Header for Grids

struct PlatformGridSectionHeader: View {
    let name: String?
    let slug: String?
    let count: Int
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                if let slug = slug {
                    PlatformIcon(slug: slug, size: 20)
                }
                Text(name ?? "Other")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text("(\(count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grouped Game Cover Grid

/// A grid that supports grouping by platform with expandable sections
struct GroupedGameCoverGrid<Item: Identifiable, Overlay: View>: View {
    let groups: [(platform: Platform?, items: [Item])]
    let expandedSections: ExpandedSectionsState
    let columns: [GridItem]
    let gameId: (Item) -> String
    let gameTitle: (Item) -> String
    let coverUrl: (Item) -> String?
    let platformId: (Item) -> String?
    let destination: (Item) -> AnyView
    let overlay: (Item) -> Overlay

    init(
        groups: [(platform: Platform?, items: [Item])],
        expandedSections: ExpandedSectionsState,
        columnCount: Int = 3,
        gameId: @escaping (Item) -> String,
        gameTitle: @escaping (Item) -> String,
        coverUrl: @escaping (Item) -> String?,
        platformId: @escaping (Item) -> String? = { _ in nil },
        destination: @escaping (Item) -> AnyView,
        @ViewBuilder overlay: @escaping (Item) -> Overlay
    ) {
        self.groups = groups
        self.expandedSections = expandedSections
        self.columns = GameCoverGridLayout.columns(count: columnCount)
        self.gameId = gameId
        self.gameTitle = gameTitle
        self.coverUrl = coverUrl
        self.platformId = platformId
        self.destination = destination
        self.overlay = overlay
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    let sectionId = group.platform?.id ?? "other"

                    Section {
                        if expandedSections.isExpanded(sectionId) {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(group.items) { item in
                                    NavigationLink(destination: destination(item)) {
                                        GameCoverWithContextMenu(
                                            gameId: gameId(item),
                                            gameTitle: gameTitle(item),
                                            coverUrl: coverUrl(item),
                                            platformId: platformId(item)
                                        ) {
                                            overlay(item)
                                        }
                                    }
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

// MARK: - Flat Game Cover Grid (no grouping)

struct FlatGameCoverGrid<Item: Identifiable, Overlay: View>: View {
    let items: [Item]
    let columns: [GridItem]
    let gameId: (Item) -> String
    let gameTitle: (Item) -> String
    let coverUrl: (Item) -> String?
    let platformId: (Item) -> String?
    let destination: (Item) -> AnyView
    let overlay: (Item) -> Overlay

    init(
        items: [Item],
        columnCount: Int = 3,
        gameId: @escaping (Item) -> String,
        gameTitle: @escaping (Item) -> String,
        coverUrl: @escaping (Item) -> String?,
        platformId: @escaping (Item) -> String? = { _ in nil },
        destination: @escaping (Item) -> AnyView,
        @ViewBuilder overlay: @escaping (Item) -> Overlay
    ) {
        self.items = items
        self.columns = GameCoverGridLayout.columns(count: columnCount)
        self.gameId = gameId
        self.gameTitle = gameTitle
        self.coverUrl = coverUrl
        self.platformId = platformId
        self.destination = destination
        self.overlay = overlay
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    NavigationLink(destination: destination(item)) {
                        GameCoverWithContextMenu(
                            gameId: gameId(item),
                            gameTitle: gameTitle(item),
                            coverUrl: coverUrl(item),
                            platformId: platformId(item)
                        ) {
                            overlay(item)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - GameRegion Extension

extension GameRegion {
    var shortName: String {
        switch self {
        case .NTSC_U: return "US"
        case .PAL: return "EU"
        case .NTSC_J: return "JP"
        case .OTHER: return "?"
        }
    }
}
