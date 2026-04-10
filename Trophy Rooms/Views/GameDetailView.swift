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
                        if let description = game.description {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About")
                                    .font(.headline)
                                Text(description)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Game Versions Section
                        if let versions = game.versions, !versions.isEmpty {
                            GameVersionsSectionView(versions: versions)
                        }

                        // Achievement Sets
                        ForEach(game.achievementSets) { set in
                            AchievementSetView(
                                set: set,
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

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let coverUrl = game.coverUrl, let url = URL(string: coverUrl) {
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
                            .foregroundColor(Color(red: 0.863, green: 0.078, blue: 0.235))
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
    let set: AchievementSet
    let isAuthenticated: Bool
    let onToggle: (Achievement) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(set.title)
                            .font(.headline)
                        if let dlc = set.dlc {
                            DLCTypeBadge(type: dlc.type)
                        }
                    }
                    HStack(spacing: 4) {
                        Text("\(set.type) • \(set.visibility.lowercased())")
                        if let version = set.gameVersion {
                            Text("•")
                            Text(version.name)
                                .fontWeight(.medium)
                        }
                        if let dlc = set.dlc {
                            Text("•")
                            Text(dlc.name)
                                .fontWeight(.medium)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(set.achievements.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }

            if set.achievements.isEmpty {
                Text("No achievements yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(set.achievements) { achievement in
                    AchievementRow(
                        achievement: achievement,
                        isAuthenticated: isAuthenticated,
                        onToggle: { onToggle(achievement) }
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct AchievementRow: View {
    let achievement: Achievement
    let isAuthenticated: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Achievement icon or placeholder
            if let iconUrl = achievement.iconUrl, let url = URL(string: iconUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "star.fill")
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(achievement.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let tier = achievement.tier {
                        TierBadge(tier: tier)
                    }
                }

                if let description = achievement.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    Text("\(achievement.points) pts")
                        .font(.caption2)
                        .foregroundColor(.blue)

                    if let userCount = achievement.userCount, userCount > 0 {
                        Text("\(userCount) users")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if isAuthenticated {
                Button(action: onToggle) {
                    Image(systemName: achievement.isCompleted == true ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(achievement.isCompleted == true ? .green : .gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
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
        NavigationLink(destination: GameFamilyView(title: gameFamily.title)) {
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
        NavigationLink(destination: GameFamilyView(title: gameFamily.title)) {
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
                    if let coverUrl = version.effectiveCoverUrl ?? version.coverUrl,
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
