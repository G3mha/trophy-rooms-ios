import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel = StatsViewModel()
    @State private var showAuth = false

    var body: some View {
        Group {
            if !authManager.isSignedIn {
                VStack(spacing: 16) {
                    Text("Sign in to view your stats")
                        .font(.headline)
                    Button("Sign In") {
                        showAuth = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.isLoading {
                ProgressView("Loading stats...")
            } else if let stats = viewModel.stats {
                VStack(spacing: 16) {
                    StatRow(title: "Trophies", value: stats.totalTrophies)
                    StatRow(title: "Achievements", value: stats.totalAchievements)
                    StatRow(title: "Games Played", value: stats.totalGamesPlayed)
                }
                .padding()
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else {
                Text("No stats available")
            }
        }
        .navigationTitle("Your Stats")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if authManager.isSignedIn {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showAuth) {
            AuthView()
        }
        .task {
            await viewModel.fetchStats()
        }
    }
}

private struct StatRow: View {
    let title: String
    let value: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text("\(value)")
                .font(.title2)
                .bold()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
