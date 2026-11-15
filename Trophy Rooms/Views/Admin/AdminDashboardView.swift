import SwiftUI

struct AdminDashboardView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    AdminPlatformsView()
                } label: {
                    Label("Platforms", systemImage: "gamecontroller")
                }

                NavigationLink {
                    AdminGamesView()
                } label: {
                    Label("Games", systemImage: "square.grid.3x3")
                }

                NavigationLink {
                    AdminGameVersionsView()
                } label: {
                    Label("Game Versions", systemImage: "square.stack.3d.up")
                }

                NavigationLink {
                    AdminAchievementSetsView()
                } label: {
                    Label("Trophy Lists", systemImage: "list.bullet.rectangle")
                }

                NavigationLink {
                    AdminAchievementsView()
                } label: {
                    Label("Trophies", systemImage: "star")
                }

                NavigationLink {
                    AdminDLCsView()
                } label: {
                    Label("DLCs & Expansions", systemImage: "puzzlepiece.extension")
                }

                NavigationLink {
                    AdminBundlesView()
                } label: {
                    Label("Bundles", systemImage: "shippingbox")
                }
            } header: {
                Text("Content Management")
            }

            Section {
                NavigationLink {
                    AdminUsersView()
                } label: {
                    Label("Users & Roles", systemImage: "person.2")
                }
            } header: {
                Text("User Management")
            }
        }
        .navigationTitle("Admin")
    }
}

#Preview {
    NavigationStack {
        AdminDashboardView()
    }
}
