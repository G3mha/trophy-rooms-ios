import SwiftUI
import ClerkKit

struct RootView: View {
    @State private var selectedTab = 0
    @StateObject private var adminViewModel = AdminViewModel()
    @EnvironmentObject private var inlineAdminContext: InlineAdminContext

    var body: some View {
        ZStack {
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

                NavigationStack {
                    BuylistView()
                }
                .tabItem {
                    Label("Buylist", systemImage: "cart")
                }
                .tag(4)

                CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "square.grid.2x2")
                }
                .tag(5)

                if adminViewModel.canAccessAdmin {
                    AdminDashboardView()
                    .tabItem {
                        Label("Admin", systemImage: "gearshape.2")
                    }
                    .tag(6)
                }
            }

            // Floating admin toolbar overlay
            if inlineAdminContext.canAccessAdmin && inlineAdminContext.currentEntity != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        AdminInlineToolbar()
                            .padding(.trailing, 16)
                            .padding(.bottom, 90) // Above tab bar
                    }
                }
            }
        }
        .task {
            await adminViewModel.checkAdminStatus()
            inlineAdminContext.adminViewModel = adminViewModel
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("ClerkUserDidChange"))) { _ in
            Task {
                await adminViewModel.checkAdminStatus()
                inlineAdminContext.adminViewModel = adminViewModel
            }
        }
    }
}
