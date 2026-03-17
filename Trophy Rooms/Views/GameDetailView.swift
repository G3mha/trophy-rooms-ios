import SwiftUI
import ClerkKit

struct GameDetailView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = GameDetailViewModel()
    @State private var showStatusPicker = false
    @State private var showAddToCollection = false

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
                onSelect: { status, platformId in
                    Task {
                        await viewModel.setGameStatus(status, platformId: platformId)
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
                    onSave: {
                        Task {
                            await viewModel.fetchCollectionForGame(gameId: gameId)
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
            }
        }
    }

    func statusColor(for status: GameStatus) -> Color {
        switch status {
        case .WISHLIST: return .pink
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
        case .WISHLIST: return .pink
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

private struct StatusPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var platformsViewModel = PlatformsViewModel.shared
    @State private var selectedPlatformId: String?

    let currentStatus: GameStatus?
    let currentPlatformId: String?
    let onSelect: (GameStatus, String?) -> Void
    let onClear: () -> Void

    var body: some View {
        NavigationStack {
            List {
                // Platform picker
                Section("Platform (Optional)") {
                    Picker("Platform", selection: $selectedPlatformId) {
                        Text("No Platform").tag(nil as String?)
                        ForEach(platformsViewModel.platforms) { platform in
                            Text(platform.name).tag(platform.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Status options
                Section("Status") {
                    ForEach(GameStatus.allCases, id: \.self) { status in
                        Button {
                            onSelect(status, selectedPlatformId)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: status.iconName)
                                    .foregroundColor(statusColor(for: status))
                                    .frame(width: 24)
                                Text(status.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if currentStatus == status {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                if currentStatus != nil {
                    Section {
                        Button(role: .destructive) {
                            onClear()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                    .frame(width: 24)
                                Text("Remove from Library")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Set Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await platformsViewModel.fetchPlatforms()
                selectedPlatformId = currentPlatformId
            }
        }
        .presentationDetents([.medium])
    }

    func statusColor(for status: GameStatus) -> Color {
        switch status {
        case .WISHLIST: return .pink
        case .BACKLOG: return .blue
        case .PLAYING: return .green
        case .PAUSED: return .orange
        case .COMPLETED: return .purple
        case .DROPPED: return .gray
        }
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
                Text(game.title)
                    .font(.title2)
                    .bold()

                if let platform = game.platform {
                    HStack(spacing: 4) {
                        Image(systemName: "gamecontroller")
                            .font(.caption)
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
                    Text(set.title)
                        .font(.headline)
                    Text("\(set.type) • \(set.visibility.lowercased())")
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
