import SwiftUI

struct UserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    let userId: String
    let userName: String?

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading profile...")
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await viewModel.fetchUserProfile(userId: userId)
                        }
                    }
                }
            } else if let user = viewModel.user {
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile header
                        ProfileHeader(user: user)

                        // Stats grid
                        if let stats = user.stats {
                            StatsGrid(stats: stats, user: user)
                        }

                        // Recent achievements
                        if !viewModel.recentAchievements.isEmpty {
                            RecentAchievementsSection(achievements: viewModel.recentAchievements)
                        }
                    }
                    .padding()
                }
            } else {
                Text("User not found")
            }
        }
        .navigationTitle(userName ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchUserProfile(userId: userId)
        }
    }
}

private struct ProfileHeader: View {
    let user: PublicUserWithAchievements

    var body: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 80, height: 80)

                Text(initials)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }

            // Name and email
            VStack(spacing: 4) {
                if let name = user.name {
                    Text(name)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Quick stats
            HStack(spacing: 32) {
                QuickStat(value: "\(user.trophyCount)", label: "Trophies", icon: "trophy.fill", color: .orange)
                QuickStat(value: "\(user.achievementCount)", label: "Achievements", icon: "star.fill", color: .yellow)
                QuickStat(value: "\(user.gamesWithAchievementsCount)", label: "Games", icon: "gamecontroller.fill", color: .blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    var initials: String {
        if let name = user.name, !name.isEmpty {
            let parts = name.split(separator: " ")
            if parts.count >= 2 {
                return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
            }
            return String(name.prefix(2)).uppercased()
        }
        return String(user.email.prefix(2)).uppercased()
    }
}

private struct QuickStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct StatsGrid: View {
    let stats: UserProfileStats
    let user: PublicUserWithAchievements

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCell(title: "Total Points", value: "\(stats.totalPoints)", icon: "star.circle.fill", color: .yellow)
                StatCell(title: "Completion Rate", value: String(format: "%.1f%%", stats.completionRate), icon: "percent", color: .green)
                StatCell(title: "Avg Points/Game", value: "\(Int(stats.averagePointsPerGame))", icon: "chart.line.uptrend.xyaxis", color: .blue)
                StatCell(title: "Games Played", value: "\(user.gamesWithAchievementsCount)", icon: "gamecontroller", color: .purple)
            }

            // Tier breakdown
            HStack(spacing: 16) {
                TierStat(tier: .PLATINUM, count: stats.platinumCount)
                TierStat(tier: .GOLD, count: stats.goldCount)
                TierStat(tier: .SILVER, count: stats.silverCount)
                TierStat(tier: .BRONZE, count: stats.bronzeCount)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

private struct StatCell: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct TierStat: View {
    let tier: AchievementTier
    let count: Int

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(tierColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )

            Text(tier.rawValue.capitalized)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    var tierColor: Color {
        tier.tierColor
    }
}

private struct RecentAchievementsSection: View {
    let achievements: [UserAchievementItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Achievements")
                .font(.headline)

            ForEach(achievements) { achievement in
                RecentAchievementRow(item: achievement)
            }
        }
    }
}

private struct RecentAchievementRow: View {
    let item: UserAchievementItem

    var body: some View {
        HStack(spacing: 12) {
            // Achievement icon
            if let iconUrl = item.achievement.iconUrl, let url = URL(string: iconUrl) {
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
                    .fill(tierColor.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "star.fill")
                            .foregroundColor(tierColor)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.achievement.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let tier = item.achievement.tier {
                        TierBadge(tier: tier)
                    }
                }

                Text(item.achievement.achievementSet.game.title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formattedDate(item.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(item.achievement.points)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    var tierColor: Color {
        guard let tier = item.achievement.tier else { return .gray }
        switch tier {
        case .PLATINUM: return Color(red: 0.898, green: 0.894, blue: 0.886)
        case .GOLD: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .SILVER: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .BRONZE: return Color(red: 0.8, green: 0.5, blue: 0.2)
        }
    }

    func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        return dateString
    }
}
