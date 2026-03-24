import SwiftUI
import ClerkKit

struct GameFamilyView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = GameFamilyViewModel()
    @State private var showAuth = false

    let title: String

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.games.isEmpty {
                ProgressView("Loading game versions...")
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Button("Try Again") {
                        Task {
                            await viewModel.fetchGamesByTitle(title)
                        }
                    }
                }
            } else if viewModel.games.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No games found")
                        .font(.headline)
                    Text("We couldn't find any games matching this title.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                List {
                    // Header Section
                    Section {
                        HStack(spacing: 16) {
                            // Cover Image
                            if let coverUrl = viewModel.coverUrl, let url = URL(string: coverUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable().aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 100, height: 133)
                                .cornerRadius(8)
                            } else {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 100, height: 133)
                                    .cornerRadius(8)
                                    .overlay(
                                        Image(systemName: "gamecontroller")
                                            .font(.system(size: 32))
                                            .foregroundColor(.secondary)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(viewModel.displayTitle)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                HStack(spacing: 16) {
                                    VStack(alignment: .leading) {
                                        Text("\(viewModel.totalAchievements)")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.accentColor)
                                        Text("Achievements")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    if viewModel.totalTrophies > 0 {
                                        VStack(alignment: .leading) {
                                            Text("\(viewModel.totalTrophies)")
                                                .font(.title3)
                                                .fontWeight(.bold)
                                                .foregroundColor(.accentColor)
                                            Text("Trophies")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }

                                Text("Available on \(viewModel.games.count) platforms")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Platform Versions Section
                    Section("Platform Versions") {
                        ForEach(viewModel.games) { game in
                            NavigationLink(destination: GameDetailView(gameId: game.id)) {
                                HStack(spacing: 12) {
                                    if let platform = game.platform {
                                        PlatformIcon(slug: platform.slug, size: 24)
                                        Text(platform.name)
                                            .font(.headline)
                                    } else {
                                        Image(systemName: "questionmark.circle")
                                            .font(.system(size: 24))
                                        Text("Unknown Platform")
                                            .font(.headline)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "star.fill")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("\(game.achievementCount)")
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(.secondary)

                                        if game.trophyCount > 0 {
                                            HStack(spacing: 4) {
                                                Image(systemName: "trophy.fill")
                                                    .font(.caption)
                                                    .foregroundColor(.yellow)
                                                Text("\(game.trophyCount)")
                                                    .font(.subheadline)
                                            }
                                            .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Game Versions")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAuth) {
            AuthView()
        }
        .task {
            await viewModel.fetchGamesByTitle(title)
        }
    }
}

#Preview {
    NavigationStack {
        GameFamilyView(title: "Silent Hill: Shattered Memories")
    }
}
