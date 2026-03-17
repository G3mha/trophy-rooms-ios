import SwiftUI
import ClerkKit
import ClerkKitUI

struct StatsView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = StatsViewModel()
    @State private var showAuth = false

    var body: some View {
        Group {
            if clerk.user == nil {
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
                if clerk.user != nil {
                    UserButton()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
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
