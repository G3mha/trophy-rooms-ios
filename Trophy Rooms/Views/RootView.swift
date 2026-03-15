import SwiftUI
import Clerk

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                GameListView()
            }
            .tabItem {
                Label("Games", systemImage: "gamecontroller")
            }

            NavigationStack {
                LeaderboardView()
            }
            .tabItem {
                Label("Leaderboards", systemImage: "chart.bar")
            }

            NavigationStack {
                ActivityView()
            }
            .tabItem {
                Label("Activity", systemImage: "clock")
            }

            NavigationStack {
                WishlistView()
            }
            .tabItem {
                Label("Wishlist", systemImage: "heart")
            }

            NavigationStack {
                TrophyRoomView()
            }
            .tabItem {
                Label("Trophy Room", systemImage: "trophy")
            }
        }
    }
}
