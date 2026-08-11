import SwiftUI

struct TrophyRoomView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var progressViewModel = GameProgressViewModel()
    @StateObject private var statsViewModel = StatsViewModel()
    @State private var showAuth = false

    var body: some View {
        Group {
            if !authManager.isSignedIn {
                SignInPrompt(icon: "trophy", message: "Sign in to view your Trophy Room") {
                    showAuth = true
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
                                        .foregroundColor(Color.accentColor)
                                    Text("Completed Games")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("\(progressViewModel.completedGames.count)")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }

                                ForEach(progressViewModel.completedGames) { progress in
                                    NavigationLink(destination: GameFamilyRouter(title: progress.gameTitle)) {
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
                                    NavigationLink(destination: GameFamilyRouter(title: progress.gameTitle)) {
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
                .contentMargins(.bottom, 100, for: .scrollContent)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .navigationBar(title: "Trophy Room")
        .sheet(isPresented: $showAuth) {
            AuthView()
        }
        .task {
            if authManager.isSignedIn {
                await progressViewModel.fetchGameProgress()
                await statsViewModel.fetchStats()
            }
        }
        .onChange(of: authManager.userId) {
            if authManager.isSignedIn {
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
            TrophyRoomStatCard(title: "Trophies", value: stats.totalTrophies, icon: "trophy.fill", color: Color.accentColor)
            TrophyRoomStatCard(title: "Achievements", value: stats.totalAchievements, icon: "star.fill", color: Cabinet.Tint.amber)
            TrophyRoomStatCard(title: "Games", value: stats.totalGamesPlayed, icon: "gamecontroller.fill", color: Cabinet.Tint.info)
        }
    }
}

private struct TrophyRoomStatCard: View {
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
        .background(Cabinet.card)
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
                        .foregroundColor(Color.accentColor)
                }
                Text("\(progress.earnedCount)/\(progress.totalCount) achievements • \(progress.earnedPoints) pts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Cabinet.card)
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
        .background(Cabinet.card)
        .cornerRadius(12)
    }
}
