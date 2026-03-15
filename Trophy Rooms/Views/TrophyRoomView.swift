import SwiftUI
import Clerk

struct TrophyRoomView: View {
    @Environment(\.clerk) private var clerk
    @StateObject private var progressViewModel = GameProgressViewModel()
    @StateObject private var statsViewModel = StatsViewModel()
    @State private var showAuth = false

    var body: some View {
        Group {
            if clerk.user == nil {
                VStack(spacing: 16) {
                    Image(systemName: "trophy")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Sign in to view your Trophy Room")
                        .font(.headline)
                    Button("Sign In") {
                        showAuth = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if progressViewModel.isLoading {
                ProgressView("Loading your progress...")
            } else if let error = progressViewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats Header
                        if let stats = statsViewModel.stats {
                            StatsHeader(stats: stats)
                        }

                        // Completed Games (Trophies)
                        if !progressViewModel.completedGames.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "trophy.fill")
                                        .foregroundColor(Color(red: 0.863, green: 0.078, blue: 0.235))
                                    Text("Completed Games")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("\(progressViewModel.completedGames.count)")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }

                                ForEach(progressViewModel.completedGames) { progress in
                                    NavigationLink(destination: GameDetailView(gameId: progress.gameId)) {
                                        CompletedGameCard(progress: progress)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // In Progress Games
                        if !progressViewModel.inProgressGames.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "hourglass")
                                        .foregroundColor(.blue)
                                    Text("In Progress")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("\(progressViewModel.inProgressGames.count)")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }

                                ForEach(progressViewModel.inProgressGames) { progress in
                                    NavigationLink(destination: GameDetailView(gameId: progress.gameId)) {
                                        GameProgressCard(progress: progress)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        // Empty state
                        if progressViewModel.completedGames.isEmpty && progressViewModel.inProgressGames.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "gamecontroller")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("No progress yet")
                                    .font(.headline)
                                Text("Start completing achievements to track your progress!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Trophy Room")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if clerk.user != nil {
                    UserButton()
                        .frame(width: 28, height: 28)
                }
            }
        }
        .sheet(isPresented: $showAuth) {
            AuthView()
        }
        .task {
            if clerk.user != nil {
                await progressViewModel.fetchGameProgress()
                await statsViewModel.fetchStats()
            }
        }
        .onChange(of: clerk.user?.id) {
            if clerk.user != nil {
                Task {
                    await progressViewModel.fetchGameProgress()
                    await statsViewModel.fetchStats()
                }
            }
        }
    }
}

private struct StatsHeader: View {
    let stats: UserStats

    var body: some View {
        HStack(spacing: 16) {
            StatCard(title: "Trophies", value: stats.totalTrophies, icon: "trophy.fill", color: Color(red: 0.863, green: 0.078, blue: 0.235))
            StatCard(title: "Achievements", value: stats.totalAchievements, icon: "star.fill", color: .yellow)
            StatCard(title: "Games", value: stats.totalGamesPlayed, icon: "gamecontroller.fill", color: .blue)
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct CompletedGameCard: View {
    let progress: GameProgress

    var body: some View {
        HStack(spacing: 12) {
            if let coverUrl = progress.gameCoverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 50, height: 70)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 70)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(progress.gameTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "trophy.fill")
                        .foregroundColor(Color(red: 0.863, green: 0.078, blue: 0.235))
                }
                Text("\(progress.earnedCount)/\(progress.totalCount) achievements • \(progress.earnedPoints) pts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct GameProgressCard: View {
    let progress: GameProgress

    var progressColor: Color {
        if progress.percentComplete >= 0.75 {
            return .green
        } else if progress.percentComplete >= 0.5 {
            return .orange
        } else {
            return .blue
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            if let coverUrl = progress.gameCoverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 50, height: 70)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 70)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(progress.gameTitle)
                    .font(.headline)
                    .foregroundColor(.primary)

                ProgressBar(progress: progress.percentComplete, foregroundColor: progressColor)

                HStack {
                    Text("\(progress.earnedCount)/\(progress.totalCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(progress.percentComplete * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(progressColor)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
