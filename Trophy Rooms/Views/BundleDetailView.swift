import SwiftUI
import ClerkKit

struct BundleDetailView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = BundleDetailViewModel()
    @StateObject private var platformsViewModel = PlatformsViewModel.shared
    @State private var showingPlatformPicker = false
    @State private var showingBuylistSheet = false
    let bundleId: String

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading bundle...")
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if let bundle = viewModel.bundle {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        BundleHeader(bundle: bundle, isAuthenticated: clerk.user != nil)

                        // Available platforms section
                        if !bundle.platforms.isEmpty {
                            BundlePlatformsSection(platforms: bundle.platforms)
                        }

                        // Ownership section (authenticated only)
                        if clerk.user != nil {
                            BundleOwnershipSection(
                                bundle: bundle,
                                isLoading: viewModel.isOwnershipLoading,
                                onAddPlatform: {
                                    showingPlatformPicker = true
                                },
                                onRemovePlatform: { platformId in
                                    Task {
                                        await viewModel.removeOwnership(platformId: platformId)
                                    }
                                }
                            )

                            // Buylist button
                            BundleBuylistSection(onAddToBuylist: {
                                showingBuylistSheet = true
                            })
                        }

                        // Description
                        if let description = bundle.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About")
                                    .font(.headline)
                                ExpandableText(content: description, lineLimit: 4)
                            }
                        }

                        // Games Section
                        if let games = bundle.gameFamilies, !games.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Games (\(games.count))")
                                    .font(.headline)

                                ForEach(games) { game in
                                    NavigationLink {
                                        GameFamilyRouter(title: game.title)
                                    } label: {
                                        BundleGameFamilyRow(gameFamily: game)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // DLCs Section
                        if let dlcs = bundle.dlcs, !dlcs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("DLCs (\(dlcs.count))")
                                    .font(.headline)

                                ForEach(dlcs) { dlc in
                                    BundleDLCRow(dlc: dlc)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Text("Bundle not found")
            }
        }
        .navigationTitle("Bundle Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchBundle(id: bundleId)
            await platformsViewModel.fetchPlatforms()
        }
        .sheet(isPresented: $showingPlatformPicker) {
            BundlePlatformPickerSheet(
                platforms: platformsViewModel.platforms,
                ownedPlatformIds: Set(viewModel.bundle?.ownedPlatforms?.map { $0.id } ?? []),
                gameFamilies: viewModel.bundle?.gameFamilies ?? [],
                onSelect: { platformId, libraryGameFamilyIds in
                    Task {
                        await viewModel.addOwnership(
                            platformId: platformId,
                            libraryGameFamilyIds: libraryGameFamilyIds
                        )
                    }
                }
            )
        }
        .sheet(isPresented: $showingBuylistSheet) {
            if let bundle = viewModel.bundle {
                AddBundleToBuylistSheet(
                    bundleId: bundle.id,
                    bundleName: bundle.name,
                    onSave: {
                        // Optionally refresh or show confirmation
                    }
                )
            }
        }
    }
}

private struct BundleHeader: View {
    let bundle: AppBundle
    let isAuthenticated: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let coverUrl = bundle.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 100, height: 100)
                .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay {
                        Image(systemName: "shippingbox")
                            .font(.largeTitle)
                            .foregroundStyle(.gray)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(bundle.name)
                    .font(.title2)
                    .bold()

                BundleTypeBadgeLarge(type: bundle.type)

                HStack(spacing: 12) {
                    if let games = bundle.gameFamilies, !games.isEmpty {
                        Label("\(games.count) games", systemImage: "gamecontroller")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if let dlcs = bundle.dlcs, !dlcs.isEmpty {
                        Label("\(dlcs.count) DLCs", systemImage: "puzzlepiece.extension")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let price = bundle.price, price > 0 {
                    Text(String(format: "$%.2f", price))
                        .font(.headline)
                        .foregroundStyle(.green)
                }
            }

            Spacer()
        }
    }
}

private struct BundleTypeBadgeLarge: View {
    let type: BundleType

    var body: some View {
        Text(type.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.2))
            .foregroundStyle(badgeColor)
            .cornerRadius(6)
    }

    var badgeColor: Color {
        switch type {
        case .BUNDLE:
            return .blue
        case .SEASON_PASS:
            return .purple
        case .COLLECTION:
            return .orange
        case .SUBSCRIPTION:
            return .green
        }
    }
}

private struct BundlePlatformsSection: View {
    let platforms: [Platform]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available On")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(platforms) { platform in
                    HStack(spacing: 6) {
                        PlatformIcon(slug: platform.slug ?? "", size: 20)
                        Text(platform.name)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
            }
        }
    }
}

private struct BundleBuylistSection: View {
    let onAddToBuylist: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Buylist")
                .font(.headline)

            Button(action: onAddToBuylist) {
                HStack {
                    Image(systemName: "cart.badge.plus")
                    Text("Add to Buylist")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct BundleOwnershipSection: View {
    let bundle: AppBundle
    let isLoading: Bool
    let onAddPlatform: () -> Void
    let onRemovePlatform: (String?) -> Void

    var ownedPlatforms: [Platform] {
        bundle.ownedPlatforms ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ownership")
                    .font(.headline)
                Spacer()
                if isLoading {
                    ProgressView()
                }
            }

            // Show owned platforms
            if !ownedPlatforms.isEmpty {
                ForEach(ownedPlatforms) { platform in
                    HStack {
                        PlatformIcon(slug: platform.slug ?? "", size: 24)
                        Text(platform.name)
                            .font(.subheadline)
                        Spacer()
                        Button {
                            onRemovePlatform(platform.id)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)
                    }
                    .padding()
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(8)
                }
            }

            // Add platform button
            Button(action: onAddPlatform) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add Platform")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
    }
}

private struct BundlePlatformPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let platforms: [Platform]
    let ownedPlatformIds: Set<String>
    let gameFamilies: [BundleGameFamily]
    let onSelect: (String?, [String]) -> Void

    @State private var selectedFamilyIds: Set<String>

    init(
        platforms: [Platform],
        ownedPlatformIds: Set<String>,
        gameFamilies: [BundleGameFamily],
        onSelect: @escaping (String?, [String]) -> Void
    ) {
        self.platforms = platforms
        self.ownedPlatformIds = ownedPlatformIds
        self.gameFamilies = gameFamilies
        self.onSelect = onSelect
        // Included games are pre-checked: owning the bundle means owning them
        _selectedFamilyIds = State(initialValue: Set(gameFamilies.map { $0.id }))
    }

    var availablePlatforms: [Platform] {
        platforms.filter { !ownedPlatformIds.contains($0.id) }
    }

    private var selectionInOrder: [String] {
        gameFamilies.map { $0.id }.filter { selectedFamilyIds.contains($0) }
    }

    var body: some View {
        NavigationStack {
            List {
                if !gameFamilies.isEmpty {
                    Section {
                        ForEach(gameFamilies) { family in
                            Button {
                                if selectedFamilyIds.contains(family.id) {
                                    selectedFamilyIds.remove(family.id)
                                } else {
                                    selectedFamilyIds.insert(family.id)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedFamilyIds.contains(family.id)
                                        ? "checkmark.circle.fill"
                                        : "circle")
                                        .font(.system(size: 20))
                                        .foregroundStyle(selectedFamilyIds.contains(family.id)
                                            ? Color.accentColor
                                            : Color.secondary)
                                    Text(family.title)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                            }
                        }
                    } header: {
                        Text("Add to Library")
                    } footer: {
                        Text("Checked games are added to your library as Backlog. Games you already track are left untouched.")
                    }
                }

                Section(gameFamilies.isEmpty ? "" : "Select Platform") {
                    // "Any Platform" option (no specific platform)
                    Button {
                        onSelect(nil, selectionInOrder)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "square.stack.3d.up")
                                .frame(width: 32)
                            Text("Any Platform")
                            Spacer()
                        }
                    }

                    ForEach(availablePlatforms) { platform in
                        Button {
                            onSelect(platform.id, selectionInOrder)
                            dismiss()
                        } label: {
                            HStack {
                                PlatformIcon(slug: platform.slug ?? "", size: 24)
                                Text(platform.name)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to Owned")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct BundleGameFamilyRow: View {
    let gameFamily: BundleGameFamily

    var body: some View {
        HStack(spacing: 12) {
            if let coverUrl = gameFamily.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 50, height: 70)
                .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 70)
                    .overlay {
                        Image(systemName: "gamecontroller")
                            .foregroundStyle(.gray)
                    }
            }

            Text(gameFamily.title)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct BundleDLCRow: View {
    let dlc: BundleDLC

    var body: some View {
        HStack(spacing: 12) {
            if let coverUrl = dlc.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 50, height: 50)
                .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "puzzlepiece.extension")
                            .foregroundStyle(.gray)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(dlc.name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let dlcType = dlc.type {
                        DLCTypeBadge(type: dlcType)
                    }
                }

                if let game = dlc.gameFamily {
                    Text("for \(game.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        BundleDetailView(bundleId: "test-id")
    }
}
