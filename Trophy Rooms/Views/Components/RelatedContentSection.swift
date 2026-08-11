import SwiftUI

// MARK: - Related Content Section

/// A reusable section component for displaying related content (DLCs, bundles, derivatives)
/// with consistent styling and header formatting.
struct RelatedContentSection<Content: View>: View {
    let title: String
    let systemImage: String
    let count: Int
    let countLabel: String?
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        systemImage: String,
        count: Int,
        countLabel: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.count = count
        self.countLabel = countLabel
        self.content = content
    }

    var body: some View {
        // Flat editorial group: brass eyebrow + rows on the canvas, so the
        // achievement plaque card stays the page's only "special" object
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundStyle(Cabinet.brass)

                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.6)
                    .foregroundStyle(Cabinet.bone.opacity(0.85))

                Text("· \(countLabel ?? "\(count)")")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            content()
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Related Item Row

/// A reusable row component for displaying related items with cover, title, badges, and navigation.
struct RelatedItemRow<Badge: View, Subtitle: View, Trailing: View>: View {
    let coverUrl: String?
    let title: String
    let coverSize: CGSize
    let coverCornerRadius: CGFloat
    let placeholderIcon: String
    @ViewBuilder let badge: () -> Badge
    @ViewBuilder let subtitle: () -> Subtitle
    @ViewBuilder let trailing: () -> Trailing

    init(
        coverUrl: String?,
        title: String,
        coverSize: CGSize = CGSize(width: 40, height: 56),
        coverCornerRadius: CGFloat = 4,
        placeholderIcon: String = "gamecontroller",
        @ViewBuilder badge: @escaping () -> Badge = { EmptyView() },
        @ViewBuilder subtitle: @escaping () -> Subtitle = { EmptyView() },
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.coverUrl = coverUrl
        self.title = title
        self.coverSize = coverSize
        self.coverCornerRadius = coverCornerRadius
        self.placeholderIcon = placeholderIcon
        self.badge = badge
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 12) {
            // Cover image with the cabinet's brass edge
            CachedImageFixed(
                url: coverUrl,
                width: coverSize.width,
                height: coverSize.height,
                cornerRadius: coverCornerRadius,
                placeholderIcon: placeholderIcon
            )
            .overlay(
                RoundedRectangle(cornerRadius: coverCornerRadius, style: .continuous)
                    .stroke(Cabinet.brass.opacity(0.25), lineWidth: 1)
            )

            // Content - the tag sits on its own line under the title so long
            // titles get the full width and nothing reads cramped
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                subtitle()

                badge()
            }

            Spacer()

            trailing()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Derivative Row

/// Row component for displaying a derivative game (fangame, ROM hack, mod)
struct DerivativeRow: View {
    let derivative: DerivativeGame

    var body: some View {
        NavigationLink(destination: GameDetailView(gameId: derivative.id)) {
            RelatedItemRow(
                coverUrl: derivative.coverUrl,
                title: derivative.title,
                coverSize: CGSize(width: 40, height: 56),
                coverCornerRadius: 4,
                placeholderIcon: "gamecontroller",
                badge: {
                    GameTypeBadge(type: derivative.type)
                },
                subtitle: {
                    if let platform = derivative.platform, let slug = platform.slug {
                        HStack(spacing: 4) {
                            PlatformIcon(slug: slug, size: 10)
                            Text(platform.name)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                },
                trailing: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bundle Row

/// Row component for displaying a bundle
struct BundleRow: View {
    let bundle: GameBundle

    var body: some View {
        NavigationLink(destination: BundleDetailView(bundleId: bundle.id)) {
            RelatedItemRow(
                coverUrl: bundle.coverUrl,
                title: bundle.name,
                coverSize: CGSize(width: 50, height: 50),
                coverCornerRadius: 8,
                placeholderIcon: "shippingbox",
                badge: {
                    BundleBadge(type: bundle.type)
                },
                subtitle: {
                    HStack(spacing: 8) {
                        if bundle.gameFamilyCount > 0 {
                            Text("\(bundle.gameFamilyCount) games")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if bundle.dlcCount > 0 {
                            Text("\(bundle.dlcCount) DLCs")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                },
                trailing: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("Derivatives Section") {
    RelatedContentSection(
        title: "Fangames, ROM Hacks & Mods",
        systemImage: "puzzlepiece.extension",
        count: 3
    ) {
        VStack(spacing: 0) {
            DerivativeRow(derivative: DerivativeGame(
                id: "1",
                title: "Pokemon Crystal Clear",
                coverUrl: nil,
                type: .ROM_HACK,
                platform: Platform(id: "1", name: "Game Boy Color", slug: "game-boy-color")
            ))
            Divider()
            DerivativeRow(derivative: DerivativeGame(
                id: "2",
                title: "AM2R",
                coverUrl: nil,
                type: .FANGAME,
                platform: Platform(id: "2", name: "PC", slug: "pc")
            ))
        }
    }
    .padding()
}

#Preview("Bundles Section") {
    RelatedContentSection(
        title: "Available In",
        systemImage: "shippingbox",
        count: 2,
        countLabel: "2 bundles"
    ) {
        VStack(spacing: 0) {
            BundleRow(bundle: GameBundle(
                id: "1",
                name: "Elden Ring + DLC Bundle",
                slug: "elden-ring-dlc-bundle",
                type: .BUNDLE,
                description: nil,
                coverUrl: nil,
                gameFamilyCount: 1,
                dlcCount: 1
            ))
        }
    }
    .padding()
}
