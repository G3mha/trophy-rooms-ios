import SwiftUI

struct DLCCard: View {
    let dlc: GameDLC
    let isOwnershipLoading: Bool
    let isAuthenticated: Bool
    let onToggleOwnership: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // DLC Cover image
            CachedImageFixed.dlc(url: dlc.effectiveCoverUrl ?? dlc.coverUrl)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(dlc.name)
                        .font(.headline)
                        .lineLimit(1)

                    DLCTypeBadge(type: dlc.type)
                }

                if let description = dlc.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if let achievementCount = dlc.achievementSetCount, achievementCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                            Text("\(achievementCount) achievement sets")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let price = dlc.price, price > 0 {
                        Text(String(format: "$%.2f", price))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else if dlc.type == .FREE_UPDATE {
                        Text("Free")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            if isAuthenticated {
                DLCOwnershipToggle(
                    isOwned: dlc.isOwned ?? false,
                    isLoading: isOwnershipLoading,
                    onToggle: onToggleOwnership
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DLCTypeBadge: View {
    let type: DLCType

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
        case .DLC:
            return .blue
        case .EXPANSION:
            return .purple
        case .FREE_UPDATE:
            return .green
        }
    }
}

struct DLCOwnershipToggle: View {
    let isOwned: Bool
    let isLoading: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: isOwned ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title2)
                    .foregroundStyle(isOwned ? .green : .gray)
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

#Preview {
    VStack {
        DLCCard(
            dlc: GameDLC(
                id: "1",
                name: "Shadow of the Erdtree",
                slug: "shadow-of-the-erdtree",
                type: .EXPANSION,
                description: "A massive expansion featuring new lands, bosses, and weapons.",
                coverUrl: nil,
                effectiveCoverUrl: nil,
                releaseDate: nil,
                price: 39.99,
                isOwned: false,
                achievementSetCount: 2
            ),
            isOwnershipLoading: false,
            isAuthenticated: true,
            onToggleOwnership: {}
        )

        DLCCard(
            dlc: GameDLC(
                id: "2",
                name: "Free Content Update",
                slug: "free-update",
                type: .FREE_UPDATE,
                description: nil,
                coverUrl: nil,
                effectiveCoverUrl: nil,
                releaseDate: nil,
                price: nil,
                isOwned: true,
                achievementSetCount: 0
            ),
            isOwnershipLoading: false,
            isAuthenticated: true,
            onToggleOwnership: {}
        )
    }
    .padding()
}
