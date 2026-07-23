import SwiftUI
import ClerkKit

struct GameDetailView: View {
    @Environment(Clerk.self) private var clerk
    @EnvironmentObject private var inlineAdminContext: InlineAdminContext
    @StateObject private var viewModel = GameDetailViewModel()
    @State private var showStatusPicker = false
    @State private var showAddToCollection = false
    @State private var showAddToBuylist = false

    let gameId: String

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading game...")
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
                        if clerk.user != nil {
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

                        // Game Versions Section
                        if let versions = game.versions, !versions.isEmpty {
                            GameVersionsSectionView(
                                versions: versions,
                                gameFamilyCoverUrl: game.coverUrl
                            )
                        }

                        // Achievement Sets
                        ForEach(game.achievementSets) { set in
                            AchievementSetView(
                                achievementSet: set,
                                isAuthenticated: clerk.user != nil,
                                onToggle: { achievement in
                                    Task {
                                        await viewModel.toggleAchievement(achievement)
                                    }
                                }
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
                                        isAuthenticated: clerk.user != nil,
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
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if clerk.user != nil {
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
        .safeAreaInset(edge: .bottom) {
            // Admin bar lives on the entity page itself, above the tab bar;
            // it renders nothing (zero inset) for non-admins.
            AdminInlineToolbar()
        }
        .task {
            await viewModel.fetchGame(id: gameId)
            if clerk.user != nil {
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
            .background(currentStatus != nil ? statusColor.opacity(0.15) : Color(.secondarySystemBackground))
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
            .background(itemCount > 0 ? Color.orange.opacity(0.15) : Color(.secondarySystemBackground))
            .foregroundColor(itemCount > 0 ? .orange : .primary)
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
            .background(isInBuylist ? Color.purple.opacity(0.15) : Color(.secondarySystemBackground))
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
                .cornerRadius(8)
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
                            .foregroundColor(.yellow)
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
        if hasMetadata {
            VStack(alignment: .leading, spacing: 12) {
                Text("Details")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    if let releaseDate = game.releaseDate {
                        MetadataItem(label: "Release Date", value: formatDate(releaseDate))
                    }
                    if let developer = game.developer {
                        MetadataItem(label: "Developer", value: developer)
                    }
                    if let publisher = game.publisher {
                        MetadataItem(label: "Publisher", value: publisher)
                    }
                    if let genre = game.genre {
                        MetadataItem(label: "Genre", value: genre)
                    }
                    if let esrbRating = game.esrbRating {
                        MetadataItem(label: "Rating", value: esrbRating)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
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

private struct MetadataItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
        }
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
            return dominantTier?.accentColor ?? Color(.systemGray3)
        }
    }

    var accentGlowColor: Color {
        accentColor.opacity(0.28)
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
                                AchievementSetChip(
                                    label: displayType,
                                    systemImage: achievementSet.type.uppercased() == "CUSTOM" ? "paintpalette.fill" : "rosette",
                                    tint: achievementSet.type.uppercased() == "CUSTOM" ? .purple : accentColor
                                )
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

                AchievementSetProgressBar(
                    progress: completionFraction,
                    accentColor: accentColor
                )
                .allowsHitTesting(false)

                HStack(spacing: 10) {
                    AchievementSetSummaryPill(
                        title: "Progress",
                        value: "\(completedCount)/\(totalCount)",
                        tint: accentColor
                    )
                    AchievementSetSummaryPill(
                        title: "Points",
                        value: "\(earnedPoints)/\(totalPoints) pts",
                        tint: .yellow
                    )
                    AchievementSetSummaryPill(
                        title: "Complete",
                        value: completionPercentText,
                        tint: completedCount == totalCount && totalCount > 0 ? .green : accentColor
                    )
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard canExpand else { return }
                withAnimation(.easeInOut(duration: 0.24)) {
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
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accentGlowColor, accentGlowColor.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 72)
                .mask(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.25), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            Capsule()
                .fill(accentColor.opacity(0.92))
                .frame(width: 84, height: 5)
                .padding(.top, 10)
        }
        .shadow(color: accentGlowColor.opacity(0.25), radius: 16, y: 8)
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
                        tint: .yellow,
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
        HStack(spacing: compact ? 4 : 5) {
            Image(systemName: systemImage)
                .font(compact ? .caption2 : .caption)
            Text(label)
                .font(compact ? .caption2 : .caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 5 : 6)
        .background(
            Capsule()
                .fill(tint.opacity(0.14))
        )
    }
}

private struct AchievementSetSummaryPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct AchievementSetProgressBar: View {
    let progress: Double
    let accentColor: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.07))

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
        .frame(height: 8)
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

    /// Get the cover URL for a version, using game family cover for default versions
    func coverUrlForVersion(_ version: GameVersion) -> String? {
        // If version has its own cover, use it
        if let effectiveCover = version.effectiveCoverUrl {
            return effectiveCover
        }
        if let versionCover = version.coverUrl {
            return versionCover
        }
        // For default versions, fall back to game family cover
        if version.isDefault, let familyCover = gameFamilyCoverUrl {
            return familyCover
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Game Versions")
                    .font(.headline)
                Spacer()
                Text("\(versions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }

            ForEach(versions) { version in
                HStack(spacing: 12) {
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
                        .cornerRadius(4)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 56)
                            .overlay {
                                Image(systemName: "square.stack.3d.up")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(version.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)

                            if version.isDefault {
                                Text("Default")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }

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
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
