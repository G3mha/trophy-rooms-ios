import SwiftUI

struct HomeView: View {
    @StateObject private var leaderboardViewModel = LeaderboardViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Leaderboard Section
                LeaderboardSection(viewModel: leaderboardViewModel)

                // Activity Section
                ActivitySection(viewModel: activityViewModel)
            }
            .padding(.vertical)
        }
        .navigationBar(title: "Home")
        .task {
            await leaderboardViewModel.fetchLeaderboard()
            await activityViewModel.fetchActivity()
        }
    }
}

// MARK: - Leaderboard Section

private struct LeaderboardSection: View {
    @ObservedObject var viewModel: LeaderboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Leaderboards")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)

            // Leaderboard type picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LeaderboardType.allCases) { type in
                        LeaderboardTypeChip(
                            type: type,
                            isSelected: viewModel.selectedType == type
                        ) {
                            viewModel.selectedType = type
                            Task {
                                await viewModel.fetchLeaderboard()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Leaderboard content
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding(.horizontal)
            } else if viewModel.selectedType == .fastest {
                FastestCompletionsPreview(entries: Array(viewModel.fastestEntries.prefix(5)))
            } else {
                LeaderboardPreview(entries: Array(viewModel.entries.prefix(5)), type: viewModel.selectedType)
            }
        }
    }
}

private struct LeaderboardTypeChip: View {
    let type: LeaderboardType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

private struct LeaderboardPreview: View {
    let entries: [LeaderboardEntry]
    let type: LeaderboardType

    var body: some View {
        VStack(spacing: 0) {
            ForEach(entries) { entry in
                NavigationLink(destination: UserProfileView(userId: entry.userId, userName: entry.userName)) {
                    LeaderboardRow(entry: entry, type: type)
                }
                if entry.id != entries.last?.id {
                    Divider()
                        .padding(.leading, 60)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let type: LeaderboardType

    var valueLabel: String {
        switch type {
        case .trophies: return "\(entry.value)"
        case .achievements: return "\(entry.value)"
        case .points: return "\(entry.value) pts"
        case .games: return "\(entry.value)"
        case .fastest: return ""
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RankBadge(rank: entry.rank)

            Text(entry.userName ?? entry.userEmail)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)

            Spacer()

            Text(valueLabel)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private struct FastestCompletionsPreview: View {
    let entries: [FastestCompletionEntry]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(entries) { entry in
                NavigationLink(destination: UserProfileView(userId: entry.userId, userName: entry.userName)) {
                    FastestRow(entry: entry)
                }
                if entry.id != entries.last?.id {
                    Divider()
                        .padding(.leading, 60)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

private struct FastestRow: View {
    let entry: FastestCompletionEntry

    var formattedTime: String {
        let hours = Int(entry.completionTimeHours)
        if hours < 1 {
            let minutes = Int(entry.completionTimeHours * 60)
            return "\(minutes)m"
        } else if hours < 24 {
            return "\(hours)h"
        } else {
            let days = hours / 24
            return "\(days)d"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RankBadge(rank: entry.rank)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.userName ?? entry.userEmail)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(entry.gameTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(formattedTime)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

private struct RankBadge: View {
    let rank: Int

    var backgroundColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.843, blue: 0.0)
        case 2: return Color(red: 0.753, green: 0.753, blue: 0.753)
        case 3: return Color(red: 0.804, green: 0.498, blue: 0.196)
        default: return Color(.systemGray5)
        }
    }

    var textColor: Color {
        switch rank {
        case 1, 2, 3: return .black
        default: return .primary
        }
    }

    var body: some View {
        Text("\(rank)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(textColor)
            .frame(width: 28, height: 28)
            .background(backgroundColor)
            .clipShape(Circle())
    }
}

// MARK: - Activity Section

private struct ActivitySection: View {
    @ObservedObject var viewModel: ActivityViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)

            // Activity filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ActivityFilter.allCases) { filter in
                        ActivityFilterChip(
                            filter: filter,
                            isSelected: viewModel.selectedFilter == filter
                        ) {
                            viewModel.selectedFilter = filter
                            viewModel.applyFilter()
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Activity content
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding(.horizontal)
            } else if viewModel.activities.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No activity yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ActivityPreview(activities: Array(viewModel.activities.prefix(10)))
            }
        }
    }
}

private struct ActivityFilterChip: View {
    let filter: ActivityFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(filter.title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.orange : Color(.secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

private struct ActivityPreview: View {
    let activities: [ActivityEntry]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(activities) { activity in
                NavigationLink(destination: UserProfileView(userId: activity.userId, userName: activity.userName)) {
                    ActivityRow(activity: activity)
                }
                if activity.id != activities.last?.id {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

private struct ActivityRow: View {
    let activity: ActivityEntry

    var icon: String {
        activity.type == "TROPHY" ? "trophy.fill" : "star.fill"
    }

    var iconColor: Color {
        if activity.type == "TROPHY" {
            return Color(red: 0.863, green: 0.078, blue: 0.235)
        }
        if let tier = activity.achievementTier {
            switch tier {
            case .GOLD: return Color(red: 1.0, green: 0.843, blue: 0.0)
            case .SILVER: return Color(red: 0.753, green: 0.753, blue: 0.753)
            case .BRONZE: return Color(red: 0.804, green: 0.498, blue: 0.196)
            }
        }
        return .yellow
    }

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: activity.earnedAt) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: activity.earnedAt) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        return activity.earnedAt
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(activity.userName ?? activity.userEmail)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if activity.type == "TROPHY" {
                    Text("Earned a trophy in \(activity.gameTitle)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    HStack(spacing: 4) {
                        Text(activity.achievementTitle ?? "Achievement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let tier = activity.achievementTier {
                            TierBadge(tier: tier)
                        }
                    }
                    Text(activity.gameTitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
