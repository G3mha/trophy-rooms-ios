import SwiftUI
import ClerkKit

struct BundleDetailView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = BundleDetailViewModel()
    @StateObject private var platformsViewModel = PlatformsViewModel.shared
    @State private var showingPlatformPicker = false
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
                onSelect: { platformId in
                    Task {
                        await viewModel.addOwnership(platformId: platformId)
                    }
                }
            )
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
    let onSelect: (String?) -> Void

    var availablePlatforms: [Platform] {
        platforms.filter { !ownedPlatformIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List {
                // "Any Platform" option (no specific platform)
                Button {
                    onSelect(nil)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "square.stack.3d.up")
                            .frame(width: 32)
                        Text("Any Platform")
                        Spacer()
                    }
                }

                if !availablePlatforms.isEmpty {
                    Section("Select Platform") {
                        ForEach(availablePlatforms) { platform in
                            Button {
                                onSelect(platform.id)
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
        .presentationDetents([.medium])
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
