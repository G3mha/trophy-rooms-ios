import SwiftUI
import ClerkKit

struct RootView: View {
    @State private var selectedTab = 0
    @StateObject private var adminViewModel = AdminViewModel()
    @EnvironmentObject private var inlineAdminContext: InlineAdminContext
    @EnvironmentObject private var adminPresentationContext: AdminPresentationContext

    private let shellAnimation = Animation.spring(response: 0.34, dampingFraction: 0.88)

    var body: some View {
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
        .toolbar(.hidden, for: .tabBar)
        .overlay(alignment: .bottom) {
            GlassTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .animation(shellAnimation, value: selectedTab)
        }
        .overlay(alignment: .bottom) {
            // Floating admin toolbar overlay
            if inlineAdminContext.canAccessAdmin && inlineAdminContext.currentEntity != nil {
                HStack {
                    Spacer()
                    AdminInlineToolbar()
                        .padding(.trailing, 16)
                        .padding(.bottom, 90)
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

// MARK: - Glass Tab Bar

private struct GlassTabBar: View {
    @Binding var selectedTab: Int

    private let glassBackground = Color.black.opacity(0.6)
    private let glassBorder = Color.white.opacity(0.2)

    var body: some View {
        HStack(spacing: 0) {
            GlassTabItem(icon: "house", selectedIcon: "house.fill", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            GlassTabItem(icon: "trophy", selectedIcon: "trophy.fill", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            GlassTabItem(icon: "books.vertical", selectedIcon: "books.vertical.fill", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            GlassTabItem(icon: "cart", selectedIcon: "cart.fill", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
            GlassTabItem(icon: "square.grid.2x2", selectedIcon: "square.grid.2x2.fill", isSelected: selectedTab == 4) {
                selectedTab = 4
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background {
            if #available(iOS 26.0, *) {
                Capsule()
                    .fill(.clear)
                    .glassEffect(.regular.interactive(), in: .capsule)
            } else {
                Capsule()
                    .fill(glassBackground)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(glassBorder, lineWidth: 1))
                    .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
            }
        }
    }
}

private struct GlassTabItem: View {
    let icon: String
    let selectedIcon: String
    let isSelected: Bool
    let action: () -> Void

    private let buttonSize: CGFloat = 48

    var body: some View {
        Button(action: action) {
            Image(systemName: isSelected ? selectedIcon : icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isSelected ? Color.accentColor : Color.white.opacity(0.7))
                .frame(width: buttonSize, height: buttonSize)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
