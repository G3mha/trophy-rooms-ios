import SwiftUI
import ClerkKit

struct LibraryView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = LibraryViewModel()
    @State private var showAuth = false
    @State private var editingItem: LibraryItem?
    @State private var showStatusPicker = false

    var body: some View {
        Group {
            if clerk.user == nil {
                VStack(spacing: 16) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Sign in to view your library")
                        .font(.headline)
                    Button("Sign In") {
                        showAuth = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.isLoading {
                ProgressView("Loading library...")
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await viewModel.fetchLibrary()
                        }
                    }
                }
            } else if viewModel.libraryItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Your library is empty")
                        .font(.headline)
                    Text("Browse games and add them to your library")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                VStack(spacing: 0) {
                    // Status and platform filter pills
                    LibraryFilterView(
                        selectedStatus: $viewModel.selectedStatus,
                        statusCounts: viewModel.statusCounts,
                        selectedPlatformId: $viewModel.selectedPlatformId,
                        availablePlatforms: viewModel.availablePlatforms
                    )

                    // Game list
                    List {
                        ForEach(viewModel.filteredItems) { item in
                            NavigationLink(destination: GameDetailView(gameId: item.gameId)) {
                                LibraryItemRow(item: item)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingItem = item
                                    showStatusPicker = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.clearGameStatus(gameId: item.gameId)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationBar(title: "Library")
        .sheet(isPresented: $showAuth) {
            AuthView()
        }
        .sheet(isPresented: $showStatusPicker) {
            if let item = editingItem {
                StatusPickerSheet(
                    currentStatus: item.status,
                    currentPlatformId: item.platformId,
                    currentVersionId: item.gameVersionId,
                    versions: [],
                    onSelect: { status, platformId, versionId in
                        Task {
                            await viewModel.setGameStatus(gameId: item.gameId, status: status, platformId: platformId, gameVersionId: versionId)
                        }
                    },
                    onClear: {
                        Task {
                            await viewModel.clearGameStatus(gameId: item.gameId)
                        }
                    }
                )
            }
        }
        .task {
            if clerk.user != nil {
                await viewModel.fetchLibrary()
            }
        }
        .onChange(of: clerk.user?.id) {
            if clerk.user != nil {
                Task {
                    await viewModel.fetchLibrary()
                }
            }
        }
    }
}

private struct LibraryFilterView: View {
    @Binding var selectedStatus: GameStatus?
    let statusCounts: [GameStatus: Int]
    @Binding var selectedPlatformId: String?
    let availablePlatforms: [(id: String, name: String, slug: String?)]

    var selectedPlatformName: String? {
        availablePlatforms.first { $0.id == selectedPlatformId }?.name
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All filter
                StatusPill(
                    title: "All",
                    count: statusCounts.values.reduce(0, +),
                    isSelected: selectedStatus == nil && selectedPlatformId == nil,
                    color: .primary
                ) {
                    selectedStatus = nil
                    selectedPlatformId = nil
                }

                // Status filters
                ForEach(GameStatus.activeStatuses, id: \.self) { status in
                    let count = statusCounts[status] ?? 0
                    if count > 0 {
                        StatusPill(
                            title: status.displayName,
                            count: count,
                            isSelected: selectedStatus == status,
                            color: statusColor(for: status)
                        ) {
                            selectedStatus = status
                        }
                    }
                }

                // Platform filter menu
                if !availablePlatforms.isEmpty {
                    Menu {
                        Button("All Platforms") {
                            selectedPlatformId = nil
                        }
                        ForEach(availablePlatforms, id: \.id) { platform in
                            Button(platform.name) {
                                selectedPlatformId = platform.id
                            }
                        }
                    } label: {
                        LibraryFilterChip(
                            title: selectedPlatformName ?? "Platform",
                            isActive: selectedPlatformId != nil
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
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

private struct StatusPill: View {
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

private struct LibraryFilterChip: View {
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

private struct LibraryItemRow: View {
    let item: LibraryItem

    var body: some View {
        HStack(spacing: 12) {
            if let coverUrl = item.gameCoverUrl, let url = URL(string: coverUrl) {
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
                Text(item.gameTitle)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    StatusBadge(status: item.status)
                    if let versionName = item.gameVersionName {
                        VersionBadge(name: versionName)
                    }
                    if let platformSlug = item.platformSlug, let platformName = item.platformName {
                        PlatformBadgeWithIcon(slug: platformSlug, name: platformName)
                    } else if let platformName = item.platformName {
                        PlatformBadge(name: platformName)
                    }
                }

                Text("\(item.achievementCount) achievements")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct PlatformBadge: View {
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gamecontroller")
                .font(.caption2)
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.15))
        .foregroundColor(.secondary)
        .cornerRadius(8)
    }
}

struct StatusBadge: View {
    let status: GameStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.caption2)
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .foregroundColor(statusColor)
        .cornerRadius(8)
    }

    var statusColor: Color {
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

struct VersionBadge: View {
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "square.stack.3d.up")
                .font(.caption2)
            Text(name)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.indigo.opacity(0.15))
        .foregroundColor(.indigo)
        .cornerRadius(8)
    }
}
