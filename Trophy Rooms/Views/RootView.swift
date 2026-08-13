import SwiftUI

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
                        .cabinetCanvas()
                }
            }

            Tab("Trophies", systemImage: "trophy.fill", value: .trophies) {
                NavigationStack {
                    TrophyRoomView()
                        .cabinetCanvas()
                }
            }

            Tab("Library", systemImage: "books.vertical.fill", value: .library) {
                NavigationStack {
                    LibraryView()
                        .cabinetCanvas()
                }
            }

            Tab("Collection", systemImage: "square.grid.2x2.fill", value: .collection) {
                NavigationStack {
                    CollectionView()
                        .cabinetCanvas()
                }
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                GlobalSearchSheet()
                    .cabinetCanvas()
            }
        }
        // Sidebar on iPad, floating tab bar on iPhone
        .tabViewStyle(.sidebarAdaptable)
        .tabBarMinimizeBehavior(.onScrollDown)
        .environmentObject(adminViewModel)
        .onAppear {
            inlineAdminContext.adminViewModel = adminViewModel
        }
        .task {
            await adminViewModel.checkAdminStatus()
            inlineAdminContext.adminViewModel = adminViewModel
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("AuthUserDidChange"))) { _ in
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

// MARK: - Global Search View

private struct GlobalSearchSheet: View {
    @StateObject private var viewModel = GlobalSearchViewModel()
    @State private var searchText = ""

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationStack {
            Group {
                if trimmedQuery.count >= 2 {
                    SearchResultsView(viewModel: viewModel, query: trimmedQuery)
                } else {
                    ContentUnavailableView(
                        "Search Trophy Rooms",
                        systemImage: "magnifyingglass",
                        description: Text("Find games, bundles, and DLCs")
                    )
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search games, users, platforms...")
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
        .onChange(of: searchText) {
            Task {
                if trimmedQuery.count >= 2 {
                    await viewModel.search(query: searchText)
                } else {
                    viewModel.clearResults()
                }
            }
        }
    }
}

private struct SearchResultsView: View {
    @ObservedObject var viewModel: GlobalSearchViewModel
    let query: String

    @Namespace private var zoomNamespace

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
            if viewModel.isLoading && !viewModel.hasResults {
                SearchSkeletonList()
            } else if !viewModel.hasResults && !viewModel.isLoading {
                ContentUnavailableView.search(text: query)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        if !gameItems.isEmpty {
                            SearchSectionHeader(title: "Games")
                            ForEach(gameItems) { item in
                                NavigationLink(
                                    destination: GameFamilyRouter(title: item.title)
                                        .navigationTransition(.zoom(sourceID: item.id, in: zoomNamespace))
                                ) {
                                    SearchItemRow(item: item)
                                }
                                .matchedTransitionSource(id: item.id, in: zoomNamespace)
                                .buttonStyle(.plain)
                            }
                        }
                        if !bundleItems.isEmpty {
                            SearchSectionHeader(title: "Bundles")
                            ForEach(bundleItems) { item in
                                NavigationLink(
                                    destination: BundleDetailView(bundleId: item.id)
                                        .navigationTransition(.zoom(sourceID: item.id, in: zoomNamespace))
                                ) {
                                    SearchItemRow(item: item)
                                }
                                .matchedTransitionSource(id: item.id, in: zoomNamespace)
                                .buttonStyle(.plain)
                            }
                        }
                        if !dlcItems.isEmpty {
                            SearchSectionHeader(title: "DLCs")
                            ForEach(dlcItems) { item in
                                NavigationLink(
                                    destination: DLCDetailView(dlcId: item.id)
                                        .navigationTransition(.zoom(sourceID: item.id, in: zoomNamespace))
                                ) {
                                    SearchItemRow(item: item)
                                }
                                .matchedTransitionSource(id: item.id, in: zoomNamespace)
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
        }
    }
}

private struct SearchSectionHeader: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 12)
            .padding(.bottom, 2)
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
                width: 48,
                height: 64,
                cornerRadius: 6,
                placeholderIcon: iconName
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                if let slugs = item.platformSlugs, !slugs.isEmpty {
                    // Platform icons stay compact where name lists would truncate
                    HStack(spacing: 5) {
                        if let typeLabel = item.typeLabel {
                            Text(typeLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ForEach(slugs, id: \.self) { slug in
                            PlatformIcon(slug: slug, size: 16)
                        }
                        if let year = item.releaseYear {
                            Text(verbatim: "· \(year)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(
            Cabinet.card,
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
}

private struct SearchSkeletonList: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { _ in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.tertiarySystemFill))
                            .frame(width: 48, height: 64)
                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: 180, height: 14)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: 120, height: 10)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(
                        Cabinet.card,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .scrollDisabled(true)
        .opacity(pulsing ? 0.5 : 1)
        .cabinetAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulsing)
        // Never start the pulse under Reduce Motion: the animation is nil
        // there, so flipping `pulsing` would dim the skeleton to 50% and
        // leave it there rather than resting at full opacity.
        .onAppear { pulsing = !reduceMotion }
        .accessibilityLabel("Searching")
    }
}
