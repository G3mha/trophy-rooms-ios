import SwiftUI
import ClerkKit

struct DLCDetailView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = DLCDetailViewModel()
    let dlcId: String

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading DLC...")
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if let dlc = viewModel.dlc {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        DLCHeader(dlc: dlc)

                        // Ownership section (authenticated only)
                        if clerk.user != nil {
                            DLCOwnershipCard(
                                isOwned: dlc.isOwned ?? false,
                                isLoading: viewModel.isOwnershipLoading,
                                onToggle: {
                                    Task {
                                        await viewModel.toggleOwnership()
                                    }
                                }
                            )
                        }

                        // Description
                        if let description = dlc.description, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About")
                                    .font(.headline)
                                ExpandableText(content: description, lineLimit: 4)
                            }
                        }

                        // Parent Game Section
                        if let gameFamily = dlc.gameFamily {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Parent Game")
                                    .font(.headline)

                                NavigationLink {
                                    GameFamilyRouter(title: gameFamily.title)
                                } label: {
                                    DLCParentGameRow(gameFamily: gameFamily)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Achievement Sets Section
                        if let achievementSets = dlc.achievementSets, !achievementSets.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Achievement Sets (\(achievementSets.count))")
                                    .font(.headline)

                                ForEach(achievementSets) { set in
                                    DLCAchievementSetRow(achievementSet: set)
                                }
                            }
                        }

                        // Bundles Section
                        if let bundles = dlc.bundles, !bundles.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Available In Bundles (\(bundles.count))")
                                    .font(.headline)

                                ForEach(bundles) { bundle in
                                    NavigationLink {
                                        BundleDetailView(bundleId: bundle.id)
                                    } label: {
                                        DLCBundleRow(bundle: bundle)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Text("DLC not found")
            }
        }
        .navigationTitle("DLC Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchDLC(id: dlcId)
        }
    }
}

// MARK: - DLC Header

private struct DLCHeader: View {
    let dlc: DLCDetail

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Cover image
            if let coverUrl = dlc.effectiveCoverUrl ?? dlc.coverUrl,
               let url = URL(string: coverUrl) {
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
                        Image(systemName: "puzzlepiece.extension")
                            .font(.largeTitle)
                            .foregroundStyle(.gray)
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(dlc.name)
                    .font(.title2)
                    .bold()

                DLCTypeBadgeLarge(type: dlc.type)

                if let releaseDate = dlc.releaseDate {
                    Text(formatDate(releaseDate))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let price = dlc.price, price > 0 {
                    Text(String(format: "$%.2f", price))
                        .font(.headline)
                        .foregroundStyle(.green)
                }
            }

            Spacer()
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withFullDate]

        if let date = inputFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            return outputFormatter.string(from: date)
        }

        // Try alternate format
        let altFormatter = DateFormatter()
        altFormatter.dateFormat = "yyyy-MM-dd"
        if let date = altFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            return outputFormatter.string(from: date)
        }

        return dateString
    }
}

// MARK: - DLC Type Badge (Large version for header)

private struct DLCTypeBadgeLarge: View {
    let type: DLCType

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
        case .DLC:
            return .blue
        case .EXPANSION:
            return .purple
        case .FREE_UPDATE:
            return .green
        }
    }
}

// MARK: - DLC Ownership Card

private struct DLCOwnershipCard: View {
    let isOwned: Bool
    let isLoading: Bool
    let onToggle: () -> Void

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

            Button(action: onToggle) {
                HStack {
                    Image(systemName: isOwned ? "checkmark.circle.fill" : "plus.circle")
                        .foregroundStyle(isOwned ? .green : .primary)
                    Text(isOwned ? "Owned" : "Add to Owned")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(isOwned ? Color.green.opacity(0.15) : Color(.secondarySystemBackground))
                .foregroundColor(.primary)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
    }
}

// MARK: - DLC Parent Game Row

private struct DLCParentGameRow: View {
    let gameFamily: GameFamilyRef

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

// MARK: - DLC Achievement Set Row

private struct DLCAchievementSetRow: View {
    let achievementSet: AchievementSetSummary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(.yellow)

            VStack(alignment: .leading, spacing: 4) {
                Text(achievementSet.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(achievementSet.achievementCount) achievements")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - DLC Bundle Row

private struct DLCBundleRow: View {
    let bundle: DLCBundleRef

    var body: some View {
        HStack(spacing: 12) {
            if let coverUrl = bundle.coverUrl, let url = URL(string: coverUrl) {
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
                        Image(systemName: "shippingbox")
                            .foregroundStyle(.gray)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(bundle.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                BundleTypeBadgeSmall(type: bundle.type)
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

// MARK: - Bundle Type Badge (Small version for rows)

private struct BundleTypeBadgeSmall: View {
    let type: BundleType

    var body: some View {
        Text(type.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.2))
            .foregroundStyle(badgeColor)
            .cornerRadius(4)
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

#Preview {
    NavigationStack {
        DLCDetailView(dlcId: "test-id")
    }
}
