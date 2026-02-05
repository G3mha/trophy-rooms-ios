import SwiftUI
import Clerk

struct GameDetailView: View {
    @Environment(\.clerk) private var clerk
    @StateObject private var viewModel = GameDetailViewModel()

    let gameId: String

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading game...")
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if let game = viewModel.game {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(game.title)
                            .font(.title2)
                            .bold()

                        if let description = game.description {
                            Text(description)
                                .foregroundColor(.secondary)
                        }

                        ForEach(game.achievementSets) { set in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(set.title)
                                            .font(.headline)
                                        Text("\(set.type) • \(set.visibility.lowercased())")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }

                                if set.achievements.isEmpty {
                                    Text("No achievements yet")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    ForEach(set.achievements) { achievement in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(achievement.title)
                                                    .font(.subheadline)
                                                if let description = achievement.description {
                                                    Text(description)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            Spacer()
                                            if clerk.user != nil {
                                                Button(action: {
                                                    Task {
                                                        await viewModel.toggleAchievement(achievement)
                                                    }
                                                }) {
                                                    Image(systemName: achievement.isCompleted == true ? "checkmark.circle.fill" : "circle")
                                                        .foregroundColor(achievement.isCompleted == true ? .green : .gray)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            } else {
                Text("Game not found")
            }
        }
        .navigationTitle("Game Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchGame(id: gameId)
        }
    }
}
