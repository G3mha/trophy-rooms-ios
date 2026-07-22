import SwiftUI
import ClerkKit

enum AppTab: Hashable {
    case home
    case trophies
    case library
    case collection
    case search
}

struct RootView: View {
    @State private var selectedTab: AppTab = .home
    @StateObject private var adminViewModel = AdminViewModel()
    @EnvironmentObject private var inlineAdminContext: InlineAdminContext
    @EnvironmentObject private var adminPresentationContext: AdminPresentationContext

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                NavigationStack {
                    HomeView()
                }
            }

            Tab("Trophies", systemImage: "trophy.fill", value: .trophies) {
                NavigationStack {
                    TrophyRoomView()
                }
            }

            Tab("Library", systemImage: "books.vertical.fill", value: .library) {
                NavigationStack {
                    LibraryView()
                }
            }

            Tab("Collection", systemImage: "square.grid.2x2.fill", value: .collection) {
                NavigationStack {
                    CollectionView()
                }
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                GlobalSearchSheet()
            }
        }
        .modifier(TabBarMinimizeModifier())
        .overlay(alignment: .bottom) {
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

// MARK: - Tab Bar Modifier

private struct TabBarMinimizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

// MARK: - Global Search View

private struct GlobalSearchSheet: View {
    @StateObject private var viewModel = GlobalSearchViewModel()
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)

                    TextField("Search games, users, platforms...", text: $searchText)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            viewModel.clearResults()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal)
                .padding(.top, 8)

                // Results
                if searchText.trimmingCharacters(in: .whitespaces).count >= 2 {
                    SearchResultsView(viewModel: viewModel)
                } else {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(.secondary.opacity(0.7))
                        Text("Search for games, users, and more")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: searchText) {
            Task {
                if searchText.trimmingCharacters(in: .whitespaces).count >= 2 {
                    await viewModel.search(query: searchText)
                } else {
                    viewModel.clearResults()
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }
}

private struct SearchResultsView: View {
    @ObservedObject var viewModel: GlobalSearchViewModel

    var gameItems: [GlobalSearchItem] {
        viewModel.items.filter { $0.type == .GAME }
    }

    var bundleItems: [GlobalSearchItem] {
        viewModel.items.filter { $0.type == .BUNDLE }
    }

    var dlcItems: [GlobalSearchItem] {
        viewModel.items.filter { $0.type == .DLC }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if !viewModel.hasResults {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.secondary.opacity(0.7))
                    Text("No results found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List {
                    if !gameItems.isEmpty {
                        Section("Games") {
                            ForEach(gameItems) { item in
                                NavigationLink(destination: GameFamilyRouter(title: item.title)) {
                                    SearchItemRow(item: item)
                                }
                            }
                        }
                    }
                    if !bundleItems.isEmpty {
                        Section("Bundles") {
                            ForEach(bundleItems) { item in
                                NavigationLink(destination: BundleDetailView(bundleId: item.id)) {
                                    SearchItemRow(item: item)
                                }
                            }
                        }
                    }
                    if !dlcItems.isEmpty {
                        Section("DLCs") {
                            ForEach(dlcItems) { item in
                                NavigationLink(destination: DLCDetailView(dlcId: item.id)) {
                                    SearchItemRow(item: item)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

private struct SearchItemRow: View {
    let item: GlobalSearchItem

    var iconName: String {
        switch item.type {
        case .GAME: return "gamecontroller.fill"
        case .BUNDLE: return "shippingbox.fill"
        case .DLC: return "puzzlepiece.extension.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            CachedImageFixed(
                url: item.coverUrl,
                width: 44,
                height: 44,
                placeholderIcon: iconName
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
