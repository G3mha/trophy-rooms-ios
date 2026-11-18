import SwiftUI

struct GameDetailView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var inlineAdminContext: InlineAdminContext
    @StateObject private var viewModel = GameDetailViewModel()
    @State private var showStatusPicker = false
    @State private var showLogPlaySheet = false
    @State private var showAddToCollection = false
    @State private var showAddToBuylist = false

    let gameId: String

    var body: some View {
        Group {
            if viewModel.isLoading {
                CabinetLoadingView("Loading game...", layout: .detail)
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if let game = viewModel.game {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header with cover and title
                        GameHeader(game: game)

                        // Base game families section (for fangames/ROM hacks/DLCs/expansions)
                        if let baseGameFamilies = game.baseGameFamilies, !baseGameFamilies.isEmpty {
                            BaseGameFamiliesSectionView(baseGameFamilies: baseGameFamilies, gameType: game.type)
                        }

                        // Library status and Collection buttons (authenticated only)
                        if authManager.isSignedIn {
                            VStack(spacing: 12) {
                                // Library Status Button
                                GameStatusButton(
                                    currentStatus: viewModel.currentStatus,
                                    isLoading: viewModel.isStatusLoading
                                ) {
                                    showStatusPicker = true
                                }

                                // Collection Button
                                CollectionButton(
                                    itemCount: viewModel.collectionItems.count,
                                    isLoading: viewModel.isCollectionLoading
                                ) {
                                    showAddToCollection = true
                                }

                                // Buylist Button
                                GameDetailBuylistButton(
                                    isInBuylist: viewModel.isInBuylist,
                                    isLoading: viewModel.isBuylistLoading
                                ) {
                                    if viewModel.isInBuylist {
                                        Task {
                                            await viewModel.toggleBuylist()
                                        }
                                    } else {
                                        showAddToBuylist = true
                                    }
                                }

                                // Log Play Button
                                GameDetailLogPlayButton {
                                    showLogPlaySheet = true
                                }
                            }
                        }

                        // Game metadata
                        GameMetadata(game: game)

                        // Screenshots
                        if let screenshots = game.screenshots, !screenshots.isEmpty {
                            ScreenshotGalleryView(screenshots: screenshots)
                        }

                        // Description
                        if let description = game.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About")
                                    .font(.headline)
                                ExpandableText(content: description, lineLimit: 4)
                            }
                        }

                        // The trophy and its list - the page's main event,
                        // ahead of edition/bundle metadata. Lists that don't
                        // gate it fold in at the bottom.
                        TrophySection(
                            sets: game.achievementSets,
                            coverUrl: game.coverUrl,
                            isAuthenticated: authManager.isSignedIn,
                            onToggle: { achievement in
                                Task {
                                    await viewModel.toggleAchievement(achievement)
                                }
                            }
                        )

                        // Game Versions Section
                        if let versions = game.versions, !versions.isEmpty {
                            GameVersionsSectionView(
                                versions: versions,
                                gameFamilyCoverUrl: game.coverUrl
                            )
                        }

                        // MARK: - Related Content Sections (Bottom)

                        // Derived game families section (fangames/ROM hacks/DLCs/expansions based on this game)
                        if let derivedGameFamilies = game.derivedGameFamilies, !derivedGameFamilies.isEmpty {
                            RelatedContentSection(
                                title: "Fangames, ROM Hacks & Mods",
                                systemImage: "puzzlepiece.extension",
                                count: derivedGameFamilies.count
                            ) {
                                ForEach(derivedGameFamilies) { derivative in
                                    DerivedGameFamilyRow(gameFamily: derivative)
                                    if derivative.id != derivedGameFamilies.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }

                        // DLCs Section
                        if let dlcs = game.dlcs, !dlcs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("DLCs & Expansions", systemImage: "puzzlepiece.extension.fill")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(dlcs.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(4)
                                }

                                ForEach(dlcs) { dlc in
                                    DLCCard(
                                        dlc: dlc,
                                        isOwnershipLoading: viewModel.isDlcOwnershipLoading.contains(dlc.id),
                                        isAuthenticated: authManager.isSignedIn,
                                        onToggleOwnership: {
                                            Task {
                                                await viewModel.toggleDlcOwnership(dlcId: dlc.id)
                                            }
                                        }
                                    )
                                }
                            }
                        }

                        // Bundles Section
                        if let bundles = game.bundles, !bundles.isEmpty {
                            RelatedContentSection(
                                title: "Available In",
                                systemImage: "shippingbox",
                                count: bundles.count,
                                countLabel: "\(bundles.count) bundle\(bundles.count == 1 ? "" : "s")"
                            ) {
                                ForEach(bundles) { bundle in
                                    BundleRow(bundle: bundle)
                                    if bundle.id != bundles.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Text("Game not found")
            }
        }
        .cabinetCanvas()
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if authManager.isSignedIn {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(GameStatus.allCases, id: \.self) { status in
                            Button {
                                Task {
                                    await viewModel.setGameStatus(status)
                                }
                            } label: {
                                Label(status.displayName, systemImage: status.iconName)
                            }
                        }
                        if viewModel.currentStatus != nil {
                            Divider()
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.clearGameStatus()
                                }
                            } label: {
                                Label("Remove from Library", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: viewModel.currentStatus?.iconName ?? "plus.circle")
                            .foregroundColor(viewModel.currentStatus != nil ? statusColor(for: viewModel.currentStatus!) : .secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showStatusPicker) {
            StatusPickerSheet(
                currentStatus: viewModel.currentStatus,
                currentPlatformId: viewModel.currentPlatformId,
                currentVersionId: viewModel.currentVersionId,
                versions: viewModel.game?.versions ?? [],
                onSelect: { status, platformId, versionId in
                    Task {
                        await viewModel.setGameStatus(status, platformId: platformId, gameVersionId: versionId)
                    }
                },
                onClear: {
                    Task {
                        await viewModel.clearGameStatus()
                    }
                }
            )
        }
        .sheet(isPresented: $showAddToCollection) {
            if let game = viewModel.game {
                AddToCollectionSheet(
                    gameId: game.id,
                    gameTitle: game.title,
                    existingItems: viewModel.collectionItems,
                    versions: game.versions ?? [],
                    gamePlatform: game.platform,
                    onSave: {
                        Task {
                            await viewModel.fetchCollectionForGame(gameId: gameId)
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showAddToBuylist) {
            if let game = viewModel.game {
                AddToBuylistSheet(
                    gameId: game.id,
                    gameTitle: game.title,
                    versions: game.versions ?? [],
                    onSave: {
                        Task {
                            await viewModel.checkBuylist(gameId: gameId)
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showLogPlaySheet) {
            if let game = viewModel.game {
                LogPlaySheet(
                    preselectedGame: PlaySessionGame(
                        id: game.id,
                        title: game.title,
                        coverUrl: game.coverUrl,
                        platform: game.platform
                    )
                ) {
                    Task {
                        await viewModel.checkGameStatus(gameId: gameId)
                    }
                }
            }
        }
        .alert("Couldn't save that trophy", isPresented: Binding(
            get: { viewModel.toggleError != nil },
            set: { if !$0 { viewModel.toggleError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.toggleError ?? "")
        }
        .safeAreaInset(edge: .bottom) {
            // Admin bar lives on the entity page itself, above the tab bar;
            // it renders nothing (zero inset) for non-admins.
            AdminInlineToolbar()
        }
        .task {
            await viewModel.fetchGame(id: gameId)
            if authManager.isSignedIn {
                await viewModel.checkGameStatus(gameId: gameId)
                await viewModel.fetchCollectionForGame(gameId: gameId)
                await viewModel.checkBuylist(gameId: gameId)
            }
            // Register entity with inline admin context when game loads
            if let game = viewModel.game {
                inlineAdminContext.setCurrentEntity(.from(game: game))
            }
        }
        .onDisappear {
            // Clear entity when navigating away
            inlineAdminContext.clearEntityIfMatches(id: gameId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .adminGameDidUpdate)) { _ in
            // Refresh game data when admin updates it
            Task {
                await viewModel.fetchGame(id: gameId)
                // Update the inline admin context with refreshed game data
                if let game = viewModel.game {
                    inlineAdminContext.setCurrentEntity(.from(game: game))
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .adminGameDidDelete)) { _ in
            // Navigate back when game is deleted (handled by parent view)
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

private struct GameStatusButton: View {
    let currentStatus: GameStatus?
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let status = currentStatus {
                    Image(systemName: status.iconName)
                    Text(status.displayName)
                        .fontWeight(.medium)
                } else {
                    Image(systemName: "plus.circle")
                    Text("Add to Library")
                        .fontWeight(.medium)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(currentStatus != nil ? statusColor.opacity(0.15) : Cabinet.card)
            .foregroundColor(currentStatus != nil ? statusColor : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    var statusColor: Color {
        guard let status = currentStatus else { return .primary }
        switch status {
        case .BACKLOG: return .blue
        case .PLAYING: return .green
        case .PAUSED: return .orange
        case .COMPLETED: return .purple
        case .DROPPED: return .gray
        }
    }
}

private struct CollectionButton: View {
    let itemCount: Int
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "archivebox")
                    if itemCount > 0 {
                        Text("In Collection (\(itemCount))")
                            .fontWeight(.medium)
                    } else {
                        Text("Add to Collection")
                            .fontWeight(.medium)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(itemCount > 0 ? Color.orange.opacity(0.15) : Cabinet.card)
            .foregroundColor(itemCount > 0 ? .orange : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

private struct GameDetailLogPlayButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                Text("Log Play Session")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Cabinet.card)
            .foregroundColor(.primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

private struct GameDetailBuylistButton: View {
    let isInBuylist: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: isInBuylist ? "cart.fill" : "cart")
                    if isInBuylist {
                        Text("In Buylist")
                            .fontWeight(.medium)
                    } else {
                        Text("Add to Buylist")
                            .fontWeight(.medium)
                    }
                }
                Spacer()
                if isInBuylist {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isInBuylist ? Color.purple.opacity(0.15) : Cabinet.card)
            .foregroundColor(isInBuylist ? .purple : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

private struct GameHeader: View {
    let game: GameDetail

    /// Use the default version's cover if available, otherwise fall back to game's cover
    var effectiveCoverUrl: String? {
        // Prefer the default version's effective cover
        if let defaultVersion = game.defaultVersion {
            if let effectiveCover = defaultVersion.effectiveCoverUrl {
                return effectiveCover
            }
            if let versionCover = defaultVersion.coverUrl {
                return versionCover
            }
        }
        // Fall back to the game's cover
        return game.coverUrl
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let coverUrl = effectiveCoverUrl {
                RemoteImage(url: coverUrl, contentMode: .fit)
                .frame(width: 100, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Cabinet.brass.opacity(0.55), lineWidth: 1.5)
                )
                .shadow(color: Cabinet.amber.opacity(0.18), radius: 18, y: 6)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(game.title)
                        .font(.title2)
                        .bold()
                    if let type = game.type, type != .BASE_GAME {
                        GameTypeBadge(type: type)
                    }
                }

                if let platform = game.platform, let slug = platform.slug {
                    HStack(spacing: 4) {
                        PlatformIcon(slug: slug, size: 14)
                        Text(platform.name)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }

                if game.trophyCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(Color.accentColor)
                        Text("\(game.trophyCount) Platinums")
                            .font(.subheadline)
                    }
                }

                // Only the sets that award the trophy, the rule the backend uses
                let totalAchievements = game.achievementSets
                    .filter(\.gatesTrophy)
                    .reduce(0) { $0 + $1.achievements.filter { $0.tier != .PLATINUM }.count }
                if totalAchievements > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(Cabinet.brass)
                        Text("\(totalAchievements)")
                            .font(.subheadline)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(totalAchievements) trophies")
                }

                if let releaseDate = game.releaseDate {
                    FactChip(icon: "calendar", label: formatReleaseDate(releaseDate))
                }
            }

            Spacer()
        }
    }
}

private struct GameMetadata: View {
    let game: GameDetail

    var hasMetadata: Bool {
        game.developer != nil || game.publisher != nil || game.genre != nil || game.esrbRating != nil
    }

    var body: some View {
        // Compact fact chips - a single date no longer gets a lonely card
        if hasMetadata {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let developer = game.developer {
                        FactChip(icon: "hammer.fill", label: developer)
                    }
                    if let publisher = game.publisher {
                        FactChip(icon: "building.2.fill", label: publisher)
                    }
                    if let genre = game.genre {
                        FactChip(icon: "tag.fill", label: genre)
                    }
                    if let esrbRating = game.esrbRating {
                        FactChip(icon: "checkmark.shield.fill", label: esrbRating)
                    }
                }
            }
        }
    }
}

private func formatReleaseDate(_ dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]

    if let date = formatter.date(from: dateString) {
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }

    return dateString
}

private struct FactChip: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Cabinet.brass)
            Text(label)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(Cabinet.card))
        .overlay(Capsule().stroke(Cabinet.brass.opacity(0.18), lineWidth: 1))
    }
}

// The trophy and its list: every achievement in the sets that gate it,
// grouped by tier, with the lists that don't gate it folded in below. The
// trophy's art stands in a cabinet niche whose light comes up as the player
// closes in on the trophy.
private extension Array where Element == Achievement {
    var withoutPlatinum: [Achievement] {
        filter { $0.tier != .PLATINUM }
    }
}

private enum TrophyFilter: String, CaseIterable {
    case all = "All"
    case notEarned = "Not earned"
    case earned = "Earned"

    func shows(_ achievement: Achievement) -> Bool {
        switch self {
        case .all: return true
        case .notEarned: return achievement.isCompleted != true
        case .earned: return achievement.isCompleted == true
        }
    }

    var emptyText: String {
        self == .earned ? "Nothing earned yet." : "All earned."
    }
}

private struct TrophySection: View {
    let sets: [AchievementSet]
    let coverUrl: String?
    let isAuthenticated: Bool
    let onToggle: (Achievement) -> Void
    @State private var chosenFilter = TrophyFilter.all
    @State private var revealsDescriptions = false
    // Hidden like every other trophy description, so it can't spoil anything
    @State private var showsPlatinumDescription = false

    // Best first, the order the list is grouped in. No Platinum: it is the
    // trophy itself and heads the card instead.
    private static let tiers: [AchievementTier] = [.GOLD, .SILVER, .BRONZE]

    private var gatingSets: [AchievementSet] {
        sets.filter(\.gatesTrophy)
    }

    private var extraSets: [AchievementSet] {
        sets.filter { !$0.gatesTrophy }
    }

    // The trophy under the game's own name. The backend awards it once
    // everything else is done, so it is neither ticked nor counted.
    private var platinum: Achievement? {
        gatingSets.flatMap(\.achievements).first { $0.tier == .PLATINUM }
    }

    private var achievements: [Achievement] {
        gatingSets.flatMap(\.achievements).withoutPlatinum
    }

    // Only a signed-in player has anything earned to filter by
    private var filter: TrophyFilter {
        isAuthenticated ? chosenFilter : .all
    }

    private var visible: [Achievement] {
        achievements.filter(filter.shows)
    }

    private var completedCount: Int {
        achievements.filter { $0.isCompleted == true }.count
    }

    private var fraction: Double {
        achievements.isEmpty ? 0 : Double(completedCount) / Double(achievements.count)
    }

    // A signed-out visitor sees the niche fully lit, and it never goes dark
    // enough to hide the silhouette
    private var glow: Double {
        isAuthenticated ? 0.25 + 0.75 * fraction : 1
    }

    private var hasPlatinumDescription: Bool {
        !(platinum?.description ?? "").isEmpty
    }

    private var hasDescriptions: Bool {
        sets.contains { $0.achievements.contains { !($0.description ?? "").isEmpty } }
    }

    // Says it's the Platinum when the Platinum carries its own name
    private var progressLine: String {
        let count = achievements.count
        let progress = isAuthenticated ? "\(completedCount) of \(count) trophies" : "Earn all \(count) trophies"
        return platinum?.title != nil ? "Platinum · \(progress)" : progress
    }

    var body: some View {
        if !achievements.isEmpty || !extraSets.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                if !achievements.isEmpty {
                    header
                }

                if isAuthenticated || hasDescriptions {
                    controls
                }

                if !achievements.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Self.tiers, id: \.self) { tier in
                            tierGroup(tier)
                        }

                        if visible.isEmpty {
                            Text(filter.emptyText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !extraSets.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        AchievementSetGroups(sets: extraSets) { set in
                            ExtraListView(
                                achievementSet: set,
                                filter: filter,
                                revealsDescriptions: revealsDescriptions,
                                isAuthenticated: isAuthenticated,
                                onToggle: onToggle
                            )
                        }
                    }
                    .padding(.top, achievements.isEmpty ? 0 : 8)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Cabinet.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Cabinet.brass.opacity(0.20), lineWidth: 1)
            )
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            niche

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(platinum?.title ?? "Platinum")
                        .font(.title3.weight(.bold))

                    if hasPlatinumDescription {
                        Button {
                            Motion.animate(.easeInOut(duration: 0.2)) { showsPlatinumDescription.toggle() }
                        } label: {
                            Image(systemName: showsPlatinumDescription ? "eye.slash" : "eye")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(showsPlatinumDescription ? "Hide description" : "Show description")
                    }
                }

                if showsPlatinumDescription, let description = platinum?.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if isAuthenticated {
                    AchievementSetProgressBar(progress: fraction, accentColor: Cabinet.brass)
                }

                Text(progressLine)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(gatingSets.map(\.title).joined(separator: " + "))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
    }

    private var controls: some View {
        VStack(alignment: .trailing, spacing: 6) {
            if isAuthenticated {
                Picker("Show", selection: $chosenFilter) {
                    ForEach(TrophyFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            if hasDescriptions {
                Button {
                    Motion.animate(.easeInOut(duration: 0.2)) { revealsDescriptions.toggle() }
                } label: {
                    Label(
                        revealsDescriptions ? "Hide descriptions" : "Show descriptions",
                        systemImage: revealsDescriptions ? "eye.slash" : "eye"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // The platinum's own icon when it has one, else the box art, framed like a
    // display piece. Icons are square, covers are 3:4.
    private var artURL: URL? {
        URL(string: platinum?.iconUrl ?? coverUrl ?? "")
    }

    private var artHeight: CGFloat {
        platinum?.iconUrl != nil ? 92 : 123
    }

    private var niche: some View {
        VStack(spacing: 0) {
            if let artURL {
                // Starts grey and dim, comes up to full colour as the player
                // closes in
                RemoteImage(url: artURL.absoluteString) { Color.clear }
                    .frame(width: 92, height: artHeight)
                    .clipped()
                    .grayscale(min(1, (1 - glow) * 1.34))
                    .brightness(-0.4 * (1 - glow))
            } else {
                TrophySilhouette(kind: .cup)
                    .fill(Cabinet.ink)
                    .frame(width: 50, height: 87)
                    .frame(width: 92, height: 106, alignment: .bottom)
            }

            // The lit shelf the trophy stands on
            Rectangle()
                .fill(Cabinet.brass)
                .frame(height: 6)
        }
        .frame(width: 92)
        .background(
            ZStack {
                Cabinet.walnutDeep
                RadialGradient(
                    colors: [Cabinet.amber.opacity(0.6 * glow), .clear],
                    center: .bottom,
                    startRadius: 0,
                    endRadius: 100
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Cabinet.brass.opacity(0.3), lineWidth: 1)
        )
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func tierGroup(_ tier: AchievementTier) -> some View {
        let inTier = visible.filter { ($0.tier ?? .BRONZE) == tier }
        if !inTier.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(tier.rawValue.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(inTier) { achievement in
                    AchievementRow(
                        achievement: achievement,
                        tracksProgress: isAuthenticated,
                        canToggle: isAuthenticated,
                        revealsDescription: revealsDescriptions,
                        onToggle: { onToggle(achievement) }
                    )
                }
            }
        }
    }
}

// A list that doesn't gate the Platinum, folded until opened
private struct ExtraListView: View {
    let achievementSet: AchievementSet
    let filter: TrophyFilter
    let revealsDescriptions: Bool
    let isAuthenticated: Bool
    let onToggle: (Achievement) -> Void
    @State private var isExpanded = false

    // The backend awards the Platinum, so it stays out of the count
    private var counted: [Achievement] {
        achievementSet.achievements.withoutPlatinum
    }

    private var countText: String {
        if isAuthenticated {
            return "\(counted.filter { $0.isCompleted == true }.count) of \(counted.count)"
        }
        return counted.count == 1 ? "1 trophy" : "\(counted.count) trophies"
    }

    private var visible: [Achievement] {
        achievementSet.achievements.filter(filter.shows)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            Button {
                Motion.animate(.easeInOut(duration: 0.24)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))

                    Text(achievementSet.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    Text(countText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(isExpanded ? "Hides the trophies" : "Shows the trophies")

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if achievementSet.achievements.isEmpty {
                        Text("No trophies in this list yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if visible.isEmpty {
                        Text(filter.emptyText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(visible) { achievement in
                            AchievementRow(
                                achievement: achievement,
                                tracksProgress: isAuthenticated,
                                // The backend awards the Platinum, so it shows without a tick
                                canToggle: isAuthenticated && achievement.tier != .PLATINUM,
                                revealsDescription: revealsDescriptions,
                                onToggle: { onToggle(achievement) }
                            )
                        }
                    }
                }
                // Plain fade: a move transition slides ghost rows across
                // neighboring content while the container resizes
                .transition(.opacity)
            }
        }
    }
}

private struct AchievementRow: View {
    let achievement: Achievement
    // Signed in, so earned and not yet earned look different
    let tracksProgress: Bool
    let canToggle: Bool
    // Shows the description without the per-trophy reveal
    let revealsDescription: Bool
    let onToggle: () -> Void

    // Descriptions can spoil the game, so each one stays hidden until asked for
    @State private var showsDescription = false

    private var hasDescription: Bool {
        !(achievement.description ?? "").isEmpty
    }

    private var isCompleted: Bool {
        achievement.isCompleted == true
    }

    private var isLocked: Bool {
        tracksProgress && !isCompleted
    }

    private var tier: AchievementTier {
        achievement.tier ?? .BRONZE
    }

    var body: some View {
        HStack(spacing: 10) {
            if canToggle {
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .strokeBorder(isCompleted ? Cabinet.brass : Color.secondary, lineWidth: 2)
                        if isCompleted {
                            Circle()
                                .fill(Cabinet.brass)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Cabinet.ink)
                        }
                    }
                    .frame(width: 24, height: 24)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isCompleted ? "Mark as not earned" : "Mark as earned")
                .accessibilityValue(achievement.title)
                .accessibilityAddTraits(isCompleted ? [.isSelected] : [])
            }

            TrophyIcon(url: achievement.iconUrl, tier: tier, isLocked: isLocked)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(achievement.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isLocked ? Color.secondary : Color.primary)
                        // The ring's colour carries the tier on screen
                        .accessibilityLabel("\(achievement.title), \(tier.accessibilityLabel)")

                    if hasDescription && !revealsDescription {
                        Button {
                            Motion.animate(.easeInOut(duration: 0.2)) { showsDescription.toggle() }
                        } label: {
                            Image(systemName: showsDescription ? "eye.slash" : "eye")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(showsDescription ? "Hide description" : "Show description")
                        .accessibilityValue(achievement.title)
                    }
                }

                if revealsDescription || showsDescription, let description = achievement.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let earnedPercent = achievement.earnedPercent {
                    Text("\(earnedPercent.formatted(.number.precision(.fractionLength(0...1))))% of players")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.leading, canToggle ? 0 : 10)
        .padding(.trailing, 12)
        .frame(minHeight: 60)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    tracksProgress && isCompleted ? Cabinet.brass.opacity(0.45) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
    }
}

// The tier shows as a metal ring around the icon. A trophy not earned yet
// goes grey inside it, and the ring keeps its metal.
private struct TrophyIcon: View {
    let url: String?
    let tier: AchievementTier
    let isLocked: Bool

    var body: some View {
        RemoteImage(url: url) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 16))
                .foregroundStyle(tier.tierColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Cabinet.ink)
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .grayscale(isLocked ? 1 : 0)
        .brightness(isLocked ? -0.25 : 0)
        .padding(3)
        .background(Circle().fill(tier.tierColor))
        .accessibilityHidden(true)
    }
}

private struct AchievementSetProgressBar: View {
    let progress: Double
    let accentColor: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Cabinet.ink.opacity(0.45))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.82), accentColor, accentColor.opacity(0.78)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * max(0, min(progress, 1)))
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Base Game Families Section

private struct BaseGameFamiliesSectionView: View {
    let baseGameFamilies: [GameFamilyRef]
    let gameType: GameType?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Based On", systemImage: "link")
                    .font(.headline)
                Spacer()
                Text("\(baseGameFamilies.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }

            ForEach(baseGameFamilies) { gameFamily in
                BaseGameFamilyRow(gameFamily: gameFamily, gameType: gameType)
                if gameFamily.id != baseGameFamilies.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(badgeColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(badgeColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    var badgeColor: Color {
        switch gameType {
        case .FANGAME:
            return .purple
        case .ROM_HACK:
            return .orange
        case .DLC, .EXPANSION:
            return .blue
        case .MOD:
            return .green
        default:
            return .gray
        }
    }
}

private struct BaseGameFamilyRow: View {
    let gameFamily: GameFamilyRef
    let gameType: GameType?

    var body: some View {
        NavigationLink(destination: GameFamilyRouter(title: gameFamily.title)) {
            HStack(spacing: 12) {
                RemoteImage(url: gameFamily.coverUrl)
                    .font(.caption)
                    .frame(width: 40, height: 56)
                    .cornerRadius(4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(gameFamily.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if let type = gameFamily.type {
                        GameTypeBadge(type: type)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Derived Game Family Row

private struct DerivedGameFamilyRow: View {
    let gameFamily: GameFamilyRef

    var body: some View {
        NavigationLink(destination: GameFamilyRouter(title: gameFamily.title)) {
            HStack(spacing: 12) {
                RemoteImage(url: gameFamily.coverUrl)
                    .font(.caption)
                    .frame(width: 40, height: 56)
                    .cornerRadius(4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(gameFamily.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if let type = gameFamily.type {
                        GameTypeBadge(type: type)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Game Versions Section

private struct GameVersionsSectionView: View {
    let versions: [GameVersion]
    let gameFamilyCoverUrl: String?

    /// Edition-specific art when the version has its own cover, otherwise
    /// this game's cover. effectiveCoverUrl is deliberately not used as a
    /// fallback: for versions shared across games (GOTY, Remastered, ...)
    /// it resolves to the FIRST linked game's cover, which can belong to a
    /// different game entirely.
    func coverUrlForVersion(_ version: GameVersion) -> String? {
        version.coverUrl ?? gameFamilyCoverUrl
    }

    var body: some View {
        // Flat editorial group matching RelatedContentSection
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "square.stack.3d.up")
                    .font(.caption)
                    .foregroundStyle(Cabinet.brass)
                Text("GAME VERSIONS")
                    .font(.caption.weight(.bold))
                    .tracking(1.6)
                    .foregroundStyle(Cabinet.bone.opacity(0.85))
                Text("· \(versions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            ForEach(versions) { version in
                HStack(spacing: 12) {
                    RemoteImage(url: coverUrlForVersion(version), icon: "square.stack.3d.up")
                    .font(.caption)
                    .frame(width: 40, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Cabinet.brass.opacity(0.25), lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 5) {
                        Text(version.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)

                        if let dlcCount = version.dlcCount, dlcCount > 0 {
                            Text("\(dlcCount) DLC\(dlcCount == 1 ? "" : "s") included")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        if let description = version.description, !description.isEmpty {
                            Text(description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        // Tag on its own line, never crowding the name
                        if version.isDefault {
                            Tag("Default")
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 6)
    }
}
