import SwiftUI

struct AdminGameRow: View {
    let game: AdminGameItem
    let isSelecting: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onTap: () -> Void
    var isSubRow: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray)
                    .onTapGesture {
                        onToggleSelection()
                    }
            }

            if !isSubRow {
                AsyncImage(url: game.coverUrl.flatMap { URL(string: $0) }) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                if isSubRow {
                    if let platformName = game.platformName {
                        HStack(spacing: 6) {
                            if let slug = game.platformSlug {
                                PlatformIcon(slug: slug, size: 16)
                            }
                            Text(platformName)
                                .font(.subheadline)
                        }
                    }
                    Text("\(game.achievementSetCount) sets")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text(game.title)
                        .font(.headline)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        if let slug = game.platformSlug {
                            PlatformIcon(slug: slug, size: 14)
                        }
                        Text("\(game.achievementSetCount) sets")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct AdminGameGroupRow: View {
    let group: AdminGameGroup

    private let maxPlatformIcons = 5

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: group.coverUrl.flatMap { URL(string: $0) }) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 50, height: 50)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(group.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    ForEach(Array(group.games.prefix(maxPlatformIcons)), id: \.id) { game in
                        if let slug = game.platformSlug {
                            PlatformIcon(slug: slug, size: 14)
                        }
                    }
                    if group.games.count > maxPlatformIcons {
                        Text("+\(group.games.count - maxPlatformIcons)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("\(group.games.count) platforms, \(group.totalAchievementSets) sets")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
