import SwiftUI
import ClerkKit

struct CollectionView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = CollectionViewModel()
    @State private var showAuth = false
    @State private var showFilters = false
    @State private var editingItem: CollectionItem?
    @State private var editingItemVersions: [GameVersion] = []
    @State private var showEditSheet = false

    var body: some View {
        let showLoading = viewModel.isLoading || !viewModel.hasLoadedOnce
        Group {
            if clerk.user == nil {
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
            } else if showLoading {
                ProgressView("Loading collection...")
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await viewModel.fetchCollection()
                        }
                    }
                }
            } else if viewModel.collectionItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Your collection is empty")
                        .font(.headline)
                    Text("Add physical games to track your collection")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                VStack(spacing: 0) {
                    // Stats header
                    if let stats = viewModel.stats {
                        CollectionStatsHeader(stats: stats)
                    }

                    // Filter bar
                    CollectionFilterBar(
                        selectedRegion: $viewModel.selectedRegion,
                        selectedPlatformId: $viewModel.selectedPlatformId,
                        availablePlatforms: viewModel.availablePlatforms,
                        showSealedOnly: $viewModel.showSealedOnly,
                        showCompleteOnly: $viewModel.showCompleteOnly
                    )

                    // Collection list
                    List {
                        ForEach(viewModel.filteredItems) { item in
                            NavigationLink(destination: GameDetailView(gameId: item.gameId)) {
                                CollectionItemRow(item: item)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingItem = item
                                    Task {
                                        await fetchVersionsForGame(gameId: item.gameId)
                                        showEditSheet = true
                                    }
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let item = viewModel.filteredItems[index]
                                Task {
                                    await viewModel.removeFromCollection(id: item.id)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
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
                        await viewModel.fetchCollection()
                    }
                }
            }
        }
        .task {
            if clerk.user != nil && !viewModel.hasLoadedOnce {
                await viewModel.fetchCollection()
            }
        }
        .onChange(of: clerk.user?.id) {
            if clerk.user != nil {
                Task {
                    await viewModel.fetchCollection()
                }
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

private struct CollectionStatsHeader: View {
    let stats: CollectionStats

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                StatCard(title: "Total", value: "\(stats.totalItems)", icon: "archivebox.fill", color: .blue)
                StatCard(title: "Sealed", value: "\(stats.sealedCount)", icon: "seal.fill", color: .purple)
                StatCard(title: "Complete", value: "\(stats.completeCount)", icon: "checkmark.seal.fill", color: .green)

                ForEach(stats.byRegion, id: \.region) { regionCount in
                    StatCard(
                        title: regionCount.region.displayName,
                        value: "\(regionCount.count)",
                        icon: "globe",
                        color: regionColor(for: regionCount.region)
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemBackground))
    }

    func regionColor(for region: GameRegion) -> Color {
        switch region {
        case .NTSC_U: return .blue
        case .PAL: return .green
        case .NTSC_J: return .red
        case .OTHER: return .gray
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 70)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Platform filter
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

                // Region filter
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

                // Sealed filter
                Button {
                    showSealedOnly.toggle()
                } label: {
                    FilterChip(title: "Sealed", isActive: showSealedOnly)
                }

                // Complete filter
                Button {
                    showCompleteOnly.toggle()
                } label: {
                    FilterChip(title: "Complete", isActive: showCompleteOnly)
                }

                // Clear all button
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
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }
}

private struct FilterChip: View {
    let title: String
    let isActive: Bool

    var body: some View {
        Text(title)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.blue : Color(.secondarySystemBackground))
            .foregroundColor(isActive ? .white : .primary)
            .cornerRadius(16)
    }
}

private struct CollectionItemRow: View {
    let item: CollectionItem

    var body: some View {
        HStack(spacing: 12) {
            if let coverUrl = item.game.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 60, height: 80)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 80)
                    .cornerRadius(8)
            }

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

                if let platform = item.platform {
                    HStack(spacing: 4) {
                        PlatformIcon(slug: platform.slug, size: 12)
                        Text(platform.name)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

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
