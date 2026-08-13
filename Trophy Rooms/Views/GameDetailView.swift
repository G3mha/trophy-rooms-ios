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
                CabinetLoadingView("Loading game...")
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

                        // Achievement Sets - the page's main event, ahead of
                        // edition/bundle metadata
                        ForEach(game.achievementSets) { set in
                            AchievementSetView(
                                achievementSet: set,
                                isAuthenticated: authManager.isSignedIn,
                                onToggle: { achievement in
                                    Task {
                                        await viewModel.toggleAchievement(achievement)
                                    }
                                }
                            )
                        }

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
            if let coverUrl = effectiveCoverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray
                }
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
                        Text("\(game.trophyCount) trophies")
                            .font(.subheadline)
                    }
                }

                let totalAchievements = game.achievementSets.reduce(0) { $0 + $1.achievements.count }
                if totalAchievements > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Cabinet.brass)
                        Text("\(totalAchievements) achievements")
                            .font(.subheadline)
                    }
                }
            }

            Spacer()
        }
    }
}

private struct GameMetadata: View {
    let game: GameDetail

    var hasMetadata: Bool {
        game.releaseDate != nil || game.developer != nil || game.publisher != nil || game.genre != nil || game.esrbRating != nil
    }

    var body: some View {
        // Compact fact chips - a single date no longer gets a lonely card
        if hasMetadata {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let releaseDate = game.releaseDate {
                        FactChip(icon: "calendar", label: formatDate(releaseDate))
                    }
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

    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }

        return dateString
    }
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

private struct AchievementSetView: View {
    let achievementSet: AchievementSet
    let isAuthenticated: Bool
    let onToggle: (Achievement) -> Void
    @State private var isExpanded = false

    var completedCount: Int {
        achievementSet.achievements.filter { $0.isCompleted == true }.count
    }

    var totalCount: Int {
        achievementSet.achievements.count
    }

    var earnedPoints: Int {
        achievementSet.achievements.reduce(0) { partialResult, achievement in
            partialResult + (achievement.isCompleted == true ? achievement.points : 0)
        }
    }

    var totalPoints: Int {
        achievementSet.achievements.reduce(0) { $0 + $1.points }
    }

    var completionFraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var completionPercentText: String {
        "\(Int((completionFraction * 100).rounded()))%"
    }

    var dominantTier: AchievementTier? {
        if achievementSet.achievements.contains(where: { $0.tier == .PLATINUM }) { return .PLATINUM }
        if achievementSet.achievements.contains(where: { $0.tier == .GOLD }) { return .GOLD }
        if achievementSet.achievements.contains(where: { $0.tier == .SILVER }) { return .SILVER }
        if achievementSet.achievements.contains(where: { $0.tier == .BRONZE }) { return .BRONZE }
        return nil
    }

    var accentColor: Color {
        if achievementSet.dlc != nil { return .blue }

        switch achievementSet.type.uppercased() {
        case "CUSTOM":
            return .purple
        case "COMMUNITY":
            return .green
        case "COMPLETIONIST":
            return .orange
        default:
            // Official/tier sets speak the cabinet's brass, not raw tier gold -
            // tier colors stay on the individual achievement badges
            return dominantTier != nil ? Cabinet.brass : Color(.systemGray3)
        }
    }

    var showsVisibilityChip: Bool {
        achievementSet.visibility.uppercased() != "PUBLIC"
    }

    var displayType: String {
        switch achievementSet.type.uppercased() {
        case "OFFICIAL":
            return "Official"
        case "COMPLETIONIST":
            return "Completionist"
        case "CUSTOM":
            return "Custom"
        case "COMMUNITY":
            return "Community"
        default:
            return achievementSet.type.capitalized
        }
    }

    var displayVisibility: String {
        achievementSet.visibility.capitalized
    }

    var canExpand: Bool {
        !achievementSet.achievements.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(achievementSet.title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .lineLimit(2)

                            if completedCount == totalCount && totalCount > 0 {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundStyle(accentColor)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                PlaqueBadge(label: displayType, tint: accentColor)
                                if showsVisibilityChip {
                                    AchievementSetChip(
                                        label: displayVisibility,
                                        systemImage: "eye.slash",
                                        tint: .secondary
                                    )
                                }
                                if let version = achievementSet.gameVersion {
                                    AchievementSetChip(
                                        label: version.name,
                                        systemImage: "square.stack.3d.up.fill",
                                        tint: .blue
                                    )
                                }
                                if let dlc = achievementSet.dlc {
                                    AchievementSetChip(
                                        label: dlc.name,
                                        systemImage: "puzzlepiece.extension.fill",
                                        tint: .blue
                                    )
                                }
                            }
                        }
                    }
                    .allowsHitTesting(false)

                    Spacer(minLength: 8)

                    HStack {
                        Text("\(totalCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.06))
                            )

                        if canExpand {
                            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(accentColor)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    AchievementSetProgressBar(
                        progress: completionFraction,
                        accentColor: accentColor
                    )

                    HStack(spacing: 5) {
                        Text("\(completedCount) of \(totalCount) unlocked")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(completionPercentText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                completedCount == totalCount && totalCount > 0 ? .green : accentColor
                            )
                        Spacer()
                        Text("\(earnedPoints)/\(totalPoints) pts")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Cabinet.brass)
                    }
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard canExpand else { return }
                Motion.animate(.easeInOut(duration: 0.24)) {
                    isExpanded.toggle()
                }
            }

            if achievementSet.achievements.isEmpty {
                Text("No achievements yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            } else if isExpanded {
                VStack(spacing: 10) {
                    ForEach(achievementSet.achievements) { achievement in
                        AchievementRow(
                            achievement: achievement,
                            isAuthenticated: isAuthenticated,
                            accentColor: accentColor,
                            onToggle: { onToggle(achievement) }
                        )
                    }
                }
                // Plain fade: a move transition slides ghost rows across
                // neighboring cards while the container resizes
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Cabinet.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.20), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            // Lit shelf edge: a thin light falling across the card's top lip
            LinearGradient(
                colors: [.clear, accentColor.opacity(0.7), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 2)
            .padding(.horizontal, 24)
        }
        .shadow(color: Color.black.opacity(0.35), radius: 14, y: 8)
    }
}

private struct AchievementRow: View {
    let achievement: Achievement
    let isAuthenticated: Bool
    let accentColor: Color
    let onToggle: () -> Void

    var isCompleted: Bool {
        achievement.isCompleted == true
    }

    var rowTint: Color {
        achievement.tier?.accentColor ?? accentColor
    }

    var body: some View {
        HStack(spacing: 12) {
            if let iconUrl = achievement.iconUrl, let url = URL(string: iconUrl) {
                AchievementIconView(
                    url: url,
                    accentColor: rowTint,
                    isCompleted: isCompleted
                )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(achievement.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isCompleted ? .primary : Color.primary.opacity(0.94))
                        .lineLimit(2)

                    if let tier = achievement.tier {
                        TierBadge(tier: tier)
                    }
                }

                if let description = achievement.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    AchievementSetChip(
                        label: "\(achievement.points) pts",
                        systemImage: "star.fill",
                        tint: Cabinet.brass,
                        compact: true
                    )

                    if let userCount = achievement.userCount, userCount > 0 {
                        Text("\(userCount) users")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            if isAuthenticated {
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .fill(isCompleted ? rowTint.opacity(0.2) : Color.white.opacity(0.06))
                            .frame(width: 34, height: 34)
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isCompleted ? rowTint : .secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isCompleted ? rowTint.opacity(0.12) : rowTint.opacity(0.055))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isCompleted ? rowTint.opacity(0.28) : rowTint.opacity(0.12), lineWidth: 1)
        )
    }
}

private struct AchievementIconView: View {
    let url: URL
    let accentColor: Color
    let isCompleted: Bool

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            case .empty:
                iconPlaceholder
            case .failure:
                iconPlaceholder
            @unknown default:
                iconPlaceholder
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accentColor.opacity(isCompleted ? 0.4 : 0.2), lineWidth: 1)
        )
        .shadow(color: accentColor.opacity(isCompleted ? 0.2 : 0.1), radius: 8, y: 3)
    }

    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(accentColor.opacity(isCompleted ? 0.18 : 0.1))
            .overlay(
                Image(systemName: "photo")
                    .font(.caption)
                    .foregroundStyle(accentColor.opacity(0.75))
            )
    }
}

private struct AchievementSetChip: View {
    let label: String
    let systemImage: String
    let tint: Color
    var compact: Bool = false

    var body: some View {
        Tag(label, icon: systemImage, tint: tint)
    }
}

/// Engraved brass nameplate - the cabinet identity's label motif. Tinted
/// gradients cover the non-official set types while keeping the plate shape.
private struct PlaqueBadge: View {
    let label: String
    var tint: Color = Cabinet.brass

    var body: some View {
        Text(label.uppercased())
            .font(.caption2.weight(.bold))
            .tracking(1.8)
            .foregroundStyle(Color(red: 0.20, green: 0.14, blue: 0.06))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.95), tint.opacity(0.72), tint.opacity(0.58)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.black.opacity(0.35), lineWidth: 1)
            )
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.white.opacity(0.30))
                    .frame(height: 1)
                    .padding(.horizontal, 3)
                    .padding(.top, 1)
            }
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
                if let coverUrl = gameFamily.coverUrl, let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 40, height: 56)
                    .cornerRadius(4)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 56)
                        .overlay {
                            Image(systemName: "gamecontroller")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                }

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
                if let coverUrl = gameFamily.coverUrl, let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 40, height: 56)
                    .cornerRadius(4)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 56)
                        .overlay {
                            Image(systemName: "gamecontroller")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                }

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
                    Group {
                        if let coverUrl = coverUrlForVersion(version),
                           let url = URL(string: coverUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 40, height: 56)
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 56)
                                .overlay {
                                    Image(systemName: "square.stack.3d.up")
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                        }
                    }
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
