import SwiftUI
import ClerkKit

struct RootView: View {
    @State private var selectedTab = 0
    @StateObject private var adminViewModel = AdminViewModel()
    @EnvironmentObject private var inlineAdminContext: InlineAdminContext
    @EnvironmentObject private var adminPresentationContext: AdminPresentationContext

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                }
                .tag(0)

                NavigationStack {
                    TrophyRoomView()
                }
                .tag(1)

                NavigationStack {
                    LibraryView()
                }
                .tag(2)

                NavigationStack {
                    BuylistView()
                }
                .tag(3)

                NavigationStack {
                    CollectionView()
                }
                .tag(4)
            }
            .safeAreaInset(edge: .bottom) {
                // Reserve space for floating tab bar
                Color.clear.frame(height: 60)
            }

            // Floating tab bar
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

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
        .environmentObject(adminViewModel)
        .onAppear {
            inlineAdminContext.adminViewModel = adminViewModel
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
        .sheet(isPresented: $adminPresentationContext.isShowingDashboard) {
            NavigationStack {
                AdminDashboardView()
            }
        }
    }
}

// MARK: - Floating Tab Bar

private struct FloatingTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            FloatingTabItem(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            FloatingTabItem(icon: "trophy.fill", title: "Trophies", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            FloatingTabItem(icon: "books.vertical.fill", title: "Library", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            FloatingTabItem(icon: "cart.fill", title: "Buylist", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
            FloatingTabItem(icon: "square.grid.2x2.fill", title: "Collection", isSelected: selectedTab == 4) {
                selectedTab = 4
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
}

private struct FloatingTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? icon : icon.replacingOccurrences(of: ".fill", with: ""))
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}
