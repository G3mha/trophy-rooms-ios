import SwiftUI
import Clerk

struct WishlistView: View {
    @Environment(\.clerk) private var clerk
    @StateObject private var viewModel = WishlistViewModel()
    @State private var showAuth = false

    var body: some View {
        Group {
            if clerk.user == nil {
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Sign in to view your wishlist")
                        .font(.headline)
                    Button("Sign In") {
                        showAuth = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if viewModel.isLoading {
                ProgressView("Loading wishlist...")
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if viewModel.wishlistItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Your wishlist is empty")
                        .font(.headline)
                    Text("Browse games and tap the heart to add them")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.wishlistItems) { item in
                        NavigationLink(destination: GameDetailView(gameId: item.gameId)) {
                            WishlistItemRow(item: item)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = viewModel.wishlistItems[index]
                            Task {
                                await viewModel.removeFromWishlist(gameId: item.gameId)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Wishlist")
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
                await viewModel.fetchWishlist()
            }
        }
        .onChange(of: clerk.user?.id) {
            if clerk.user != nil {
                Task {
                    await viewModel.fetchWishlist()
                }
            }
        }
    }
}

private struct WishlistItemRow: View {
    let item: WishlistItem

    var body: some View {
        HStack(spacing: 12) {
            if let coverUrl = item.gameCoverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 60, height: 80)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 80)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.gameTitle)
                    .font(.headline)
                    .lineLimit(2)

                Text("\(item.achievementCount) achievements")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Added \(formattedDate(item.addedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
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
