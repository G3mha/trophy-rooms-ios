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
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
        }
    }
}
