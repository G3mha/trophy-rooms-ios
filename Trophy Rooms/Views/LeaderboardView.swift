import SwiftUI

struct LeaderboardView: View {
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Picker("Leaderboard Type", selection: $viewModel.selectedType) {
                ForEach(LeaderboardType.allCases) { type in
                    Label(type.title, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                if viewModel.isLoading {
                    Spacer()
                    CabinetLoadingView("Loading leaderboard...")
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Spacer()
                } else if viewModel.selectedType == .fastest {
                    FastestCompletionsList(entries: viewModel.fastestEntries)
                } else {
                    LeaderboardList(entries: viewModel.entries, type: viewModel.selectedType)
                }
            }
        }
        .navigationTitle("Leaderboards")
        .onChange(of: viewModel.selectedType) {
            Task {
                await viewModel.fetchLeaderboard()
            }
        }
        .task {
            await viewModel.fetchLeaderboard()
        }
    }
}

private struct LeaderboardList: View {
    let entries: [LeaderboardEntry]
    let type: LeaderboardType

    var body: some View {
        if entries.isEmpty {
            Spacer()
            Text("No entries yet")
                .foregroundColor(.secondary)
            Spacer()
        } else {
            List(entries) { entry in
                NavigationLink(destination: UserProfileView(userId: entry.userId, userName: entry.userName)) {
                    LeaderboardEntryRow(entry: entry, type: type)
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct LeaderboardEntryRow: View {
    let entry: LeaderboardEntry
    let type: LeaderboardType

    var valueLabel: String {
        switch type {
        case .trophies: return "\(entry.value) trophies"
        case .achievements: return "\(entry.value) achievements"
        case .points: return "\(entry.value) points"
        case .games: return "\(entry.value) games"
        case .fastest: return ""
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RankBadge(rank: entry.rank)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.userName ?? entry.userEmail)
                    .font(.headline)
                Text(valueLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct FastestCompletionsList: View {
    let entries: [FastestCompletionEntry]

    var body: some View {
        if entries.isEmpty {
            Spacer()
            Text("No completions yet")
                .foregroundColor(.secondary)
            Spacer()
        } else {
            List(entries) { entry in
                NavigationLink(destination: UserProfileView(userId: entry.userId, userName: entry.userName)) {
                    FastestCompletionRow(entry: entry)
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct FastestCompletionRow: View {
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
                    .font(.headline)
                Text(entry.gameTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(formattedTime)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

private struct RankBadge: View {
    let rank: Int

    var backgroundColor: Color {
        // Medal colors reuse the achievement tier palette
        switch rank {
        case 1: return AchievementTier.GOLD.tierColor
        case 2: return AchievementTier.SILVER.tierColor
        case 3: return AchievementTier.BRONZE.tierColor
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
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(textColor)
            .frame(width: 36, height: 36)
            .background(backgroundColor)
            .clipShape(Circle())
    }
}
