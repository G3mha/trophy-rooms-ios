import SwiftUI
import Combine

// MARK: - Game Cover Cell

/// A reusable game cover cell with optional overlay badges and context menu support
/// Uses CachedImage internally for reliable loading and caching
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
        CachedImage(
            url: coverUrl,
            aspectRatio: aspectRatio,
            cornerRadius: cornerRadius
        )
        .accessibilityLabel(title)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(overlay())
        // The cell draws cover art and nothing else - `title` is passed in but
        // never rendered - so without this the grid is a wall of unlabelled
        // images to VoiceOver. Combining folds the overlay badges (status,
        // region, group) into one announcement after the title.
        .accessibilityElement(children: .combine)
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
        .accessibilityElement()
        .accessibilityLabel("Multiple editions")
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
                .foregroundColor(Cabinet.inkOn(statusColor))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(statusColor)
                .cornerRadius(4)
                .padding(4)
            }
            Spacer()
        }
        // Icon + colour only, no text: the status has to reach VoiceOver
        // some other way.
        .accessibilityElement()
        .accessibilityLabel(status.displayName)
    }

    var statusColor: Color {
        switch status {
        case .BACKLOG: return Cabinet.Tint.info
        case .PLAYING: return Cabinet.Tint.positive
        case .PAUSED: return Cabinet.Tint.warm
        case .COMPLETED: return Cabinet.Tint.violet
        case .DROPPED: return Cabinet.Tint.muted
        }
    }
}

/// Region overlay badge for collection items (top-left corner)
struct RegionOverlayBadge: View {
    let region: GameRegion

    var body: some View {
        VStack {
            HStack {
                Tag(region.shortName, tint: regionColor, style: .overlay)
                    .padding(4)
                Spacer()
            }
            Spacer()
        }
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

/// Badge color per collector condition
extension CollectionCondition {
    var badgeColor: Color {
        switch self {
        case .digital: return Cabinet.Tint.info
        case .sealed: return Cabinet.Tint.violet
        case .cib: return Cabinet.Tint.positive
        case .loose: return Cabinet.Tint.warm
        case .noManual, .noBox: return Cabinet.Tint.amber
        case .noGame: return Cabinet.Tint.alert
        case .unspecified: return Cabinet.Tint.muted
        }
    }
}

/// Condition indicators overlay for collection items (bottom):
/// the collector tag (CIB, Loose, Sealed, ...) plus component icons
struct CollectionConditionOverlay: View {
    let condition: CollectionCondition
    let hasDisc: Bool
    let hasBox: Bool
    let hasManual: Bool

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 2) {
                if let label = condition.label {
                    Text(label)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(condition.badgeColor.legible(on: Cabinet.ink))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 2)
                if condition != .sealed && condition != .digital {
                    if hasDisc { conditionIcon("opticaldisc", label: "Has disc", color: .white) }
                    if hasBox { conditionIcon("shippingbox.fill", label: "Has box", color: .white) }
                    if hasManual { conditionIcon("book.closed.fill", label: "Has manual", color: .white) }
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

    private func conditionIcon(_ name: String, label: String, color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 10))
            .foregroundColor(color)
            .accessibilityLabel(label)
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
                    .foregroundColor(Cabinet.inkOn(priorityColor))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(priorityColor)
                    .cornerRadius(4)
                    .padding(4)
            }
            Spacer()
        }
        // The marker is punctuation ("!!!"), which VoiceOver reads literally
        // or skips entirely - name the priority instead.
        .accessibilityElement()
        .accessibilityLabel("\(priority.displayName) priority")
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
        case .HIGH: return Cabinet.Tint.alert
        case .MEDIUM: return Cabinet.Tint.warm
        case .LOW: return Cabinet.Tint.positive
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
                    .foregroundColor(Cabinet.inkOn(itemTypeColor))
                    .padding(5)
                    .background(itemTypeColor)
                    .cornerRadius(4)
                    .padding(4)
                Spacer()
            }
            Spacer()
        }
        .accessibilityElement()
        .accessibilityLabel(itemType.displayName)
    }

    var itemTypeColor: Color {
        switch itemType {
        case .GAME: return Cabinet.Tint.info
        case .DLC: return Cabinet.Tint.violet
        case .BUNDLE: return Cabinet.Tint.violet
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
                    .foregroundColor(Cabinet.inkOn(conditionColor))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(conditionColor)
                    .cornerRadius(4)
                    .padding(4)
            }
            Spacer()
        }
        // "NM"/"VG" get spelled out letter by letter; say the full grade.
        .accessibilityElement()
        .accessibilityLabel(condition.displayName)
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

    init(spacing: CGFloat = 12) {
        self.columns = GameCoverGridLayout.columns(spacing: spacing)
    }

    var body: some View {
        // This is just a configuration holder - use the static method
        EmptyView()
    }

    /// Adaptive columns: about three across on iPhone widths, scaling up
    /// naturally on iPad without per-screen column counts.
    static func columns(spacing: CGFloat = 12) -> [GridItem] {
        [GridItem(.adaptive(minimum: 105, maximum: 160), spacing: spacing)]
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
            .background(Cabinet.canvas)
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
        self.columns = GameCoverGridLayout.columns()
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
        self.columns = GameCoverGridLayout.columns()
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
