import SwiftUI
import ClerkKit

struct RootView: View {
    @State private var selectedTab = 0
    @StateObject private var adminViewModel = AdminViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)

            NavigationStack {
                GameListView()
            }
            .tabItem {
                Label("Games", systemImage: "gamecontroller")
            }
            .tag(1)

            NavigationStack {
                TrophyRoomView()
            }
            .tabItem {
                Label("Trophy Room", systemImage: "trophy")
            }
            .tag(2)

            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            .tag(3)

            CollectionView()
            .tabItem {
                Label("Collection", systemImage: "square.grid.2x2")
            }
            .tag(4)

            if adminViewModel.canAccessAdmin {
                AdminDashboardView()
                .tabItem {
                    Label("Admin", systemImage: "gearshape.2")
                }
                .tag(5)
            }
        }
        .task {
            await adminViewModel.checkAdminStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ClerkUserDidChange"))) { _ in
            Task {
                await adminViewModel.checkAdminStatus()
            }
        }
    }
}
