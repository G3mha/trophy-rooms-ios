import SwiftUI
import ClerkKit

struct BundleDetailView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = BundleDetailViewModel()
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

                        // Ownership toggle (authenticated only)
                        if clerk.user != nil {
                            BundleOwnershipButton(
                                isOwned: bundle.isOwned ?? false,
                                isLoading: viewModel.isOwnershipLoading,
                                onToggle: {
                                    Task {
                                        await viewModel.toggleOwnership()
                                    }
                                }
                            )
                        }

                        // Description
                        if let description = bundle.description {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About")
                                    .font(.headline)
                                Text(description)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Games Section
                        if let games = bundle.games, !games.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Games (\(games.count))")
                                    .font(.headline)

                                ForEach(games) { game in
                                    NavigationLink {
                                        GameDetailView(gameId: game.id)
                                    } label: {
                                        BundleGameRow(game: game)
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
                    if let games = bundle.games, !games.isEmpty {
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

private struct BundleOwnershipButton: View {
    let isOwned: Bool
    let isLoading: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: isOwned ? "checkmark.circle.fill" : "plus.circle")
                    Text(isOwned ? "Owned" : "Mark as Owned")
                        .fontWeight(.medium)
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isOwned ? Color.green.opacity(0.15) : Color(.secondarySystemBackground))
            .foregroundColor(isOwned ? .green : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

private struct BundleGameRow: View {
    let game: BundleGame

    var body: some View {
        HStack(spacing: 12) {
            if let coverUrl = game.coverUrl, let url = URL(string: coverUrl) {
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
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(game.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let platform = game.platform, let slug = platform.slug {
                    HStack(spacing: 4) {
                        PlatformIcon(slug: slug, size: 12)
                        Text(platform.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

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

                if let game = dlc.game {
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
