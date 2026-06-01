import SwiftUI
import Combine

// MARK: - Game Context Menu Actions

/// A reusable context menu for game-related actions
/// Use this component to add consistent long-press menus across the app
struct GameContextMenuActions: View {
    let gameId: String
    let gameTitle: String
    let platformId: String?

    // Callbacks for actions that need sheet presentation
    var onAddToBuylist: (() -> Void)?
    var onAddToCollection: (() -> Void)?
    var onAddToLibrary: (() -> Void)?

    var body: some View {
        Group {
            // Add to Buylist
            if let onAddToBuylist = onAddToBuylist {
                Button {
                    onAddToBuylist()
                } label: {
                    Label("Add to Buylist", systemImage: "cart.badge.plus")
                }
            }

            // Add to Collection
            if let onAddToCollection = onAddToCollection {
                Button {
                    onAddToCollection()
                } label: {
                    Label("Add to Collection", systemImage: "tray.full")
                }
            }

            // Add to Library
            if let onAddToLibrary = onAddToLibrary {
                Button {
                    onAddToLibrary()
                } label: {
                    Label("Add to Library", systemImage: "books.vertical")
                }
            }
        }
    }
}

// MARK: - Game Context Menu Modifier

/// A view modifier that adds a context menu with game actions
struct GameContextMenuModifier: ViewModifier {
    let gameId: String
    let gameTitle: String
    let platformId: String?

    @Binding var showBuylistSheet: Bool
    @Binding var showCollectionSheet: Bool
    @Binding var showLibrarySheet: Bool
    @Binding var selectedGameId: String?
    @Binding var selectedGameTitle: String?
    @Binding var selectedPlatformId: String?

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    selectedGameId = gameId
                    selectedGameTitle = gameTitle
                    selectedPlatformId = platformId
                    showBuylistSheet = true
                } label: {
                    Label("Add to Buylist", systemImage: "cart.badge.plus")
                }

                Button {
                    selectedGameId = gameId
                    selectedGameTitle = gameTitle
                    selectedPlatformId = platformId
                    showCollectionSheet = true
                } label: {
                    Label("Add to Collection", systemImage: "tray.full")
                }

                Button {
                    selectedGameId = gameId
                    selectedGameTitle = gameTitle
                    selectedPlatformId = platformId
                    showLibrarySheet = true
                } label: {
                    Label("Add to Library", systemImage: "books.vertical")
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Adds a game context menu with buylist, collection, and library actions
    func gameContextMenu(
        gameId: String,
        gameTitle: String,
        platformId: String? = nil,
        showBuylistSheet: Binding<Bool>,
        showCollectionSheet: Binding<Bool>,
        showLibrarySheet: Binding<Bool>,
        selectedGameId: Binding<String?>,
        selectedGameTitle: Binding<String?>,
        selectedPlatformId: Binding<String?>
    ) -> some View {
        modifier(GameContextMenuModifier(
            gameId: gameId,
            gameTitle: gameTitle,
            platformId: platformId,
            showBuylistSheet: showBuylistSheet,
            showCollectionSheet: showCollectionSheet,
            showLibrarySheet: showLibrarySheet,
            selectedGameId: selectedGameId,
            selectedGameTitle: selectedGameTitle,
            selectedPlatformId: selectedPlatformId
        ))
    }
}

// MARK: - Simplified Context Menu for Quick Actions

/// A simpler context menu that handles its own state
/// Use when you don't need to coordinate with external sheets
struct SimpleGameContextMenu<Content: View>: View {
    let gameId: String
    let gameTitle: String
    let platformId: String?
    let content: () -> Content

    @State private var showBuylistSheet = false
    @State private var showCollectionSheet = false
    @State private var showLibrarySheet = false

    @StateObject private var buylistViewModel = QuickBuylistViewModel()

    init(
        gameId: String,
        gameTitle: String,
        platformId: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.gameId = gameId
        self.gameTitle = gameTitle
        self.platformId = platformId
        self.content = content
    }

    var body: some View {
        content()
            .contentShape(Rectangle())
            .contextMenu {
                Button {
                    Task {
                        await buylistViewModel.addToBuylist(gameId: gameId)
                    }
                } label: {
                    Label("Add to Buylist", systemImage: "cart.badge.plus")
                }

                Button {
                    showCollectionSheet = true
                } label: {
                    Label("Add to Collection", systemImage: "tray.full")
                }

                Button {
                    showLibrarySheet = true
                } label: {
                    Label("Add to Library", systemImage: "books.vertical")
                }
            }
            .sheet(isPresented: $showCollectionSheet) {
                QuickAddToCollectionSheet(gameId: gameId, gameTitle: gameTitle)
            }
            .sheet(isPresented: $showLibrarySheet) {
                QuickAddToLibrarySheet(gameId: gameId, gameTitle: gameTitle)
            }
    }
}

// MARK: - Quick Buylist ViewModel

class QuickBuylistViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    func addToBuylist(gameId: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
        }

        let mutation = """
        mutation AddToBuylist($input: AddToBuylistInput!) {
            addToBuylist(input: $input) {
                success
                buylistItem {
                    id
                }
            }
        }
        """

        let input: [String: Any] = [
            "gameId": gameId,
            "priority": "MEDIUM"
        ]

        do {
            let _: AddToBuylistResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["input": input]
            )
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Quick Add to Collection Sheet

struct QuickAddToCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddToCollectionViewModel()
    @StateObject private var platformsViewModel = PlatformsViewModel.shared
    @StateObject private var versionsViewModel = GameVersionsViewModel()

    let gameId: String
    let gameTitle: String

    var filteredVersions: [GameVersion] {
        guard let platformId = viewModel.platformId else {
            return versionsViewModel.versions
        }
        return versionsViewModel.versions.filter { version in
            guard let games = version.games else { return true }
            return games.contains { $0.platform?.id == platformId }
        }
    }

    var selectedVersion: GameVersion? {
        guard let versionId = viewModel.gameVersionId else { return nil }
        return filteredVersions.first { $0.id == versionId }
    }

    var isDigitalOnlyVersion: Bool {
        selectedVersion?.digitalOnly ?? false
    }

    var isFormValid: Bool {
        viewModel.gameVersionId != nil
    }

    private func autoSelectVersion() {
        if viewModel.gameVersionId != nil { return }
        if filteredVersions.count == 1 {
            viewModel.gameVersionId = filteredVersions[0].id
        } else if let defaultVersion = filteredVersions.first(where: { $0.isDefault }) {
            viewModel.gameVersionId = defaultVersion.id
        } else if let firstVersion = filteredVersions.first {
            viewModel.gameVersionId = firstVersion.id
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if platformsViewModel.platforms.count > 1 {
                        Picker("Platform", selection: $viewModel.platformId) {
                            Text("No Platform").tag(nil as String?)
                            ForEach(platformsViewModel.platforms) { platform in
                                Text(platform.name).tag(platform.id as String?)
                            }
                        }
                    }

                    if versionsViewModel.isLoading {
                        HStack {
                            Text("Version")
                            Spacer()
                            ProgressView()
                        }
                    } else if filteredVersions.isEmpty {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("No versions available")
                                .foregroundStyle(.red)
                        }
                    } else if filteredVersions.count == 1 {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(filteredVersions[0].name)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Picker("Version", selection: $viewModel.gameVersionId) {
                            ForEach(filteredVersions, id: \.id) { version in
                                Text(version.name).tag(version.id as String?)
                            }
                        }
                    }

                    Picker("Region", selection: $viewModel.region) {
                        ForEach(GameRegion.allCases, id: \.self) { region in
                            Text(region.displayName).tag(region)
                        }
                    }

                    Toggle("Digital Copy", isOn: $viewModel.isDigital)
                        .disabled(isDigitalOnlyVersion)
                }

                Section("Physical Condition") {
                    Toggle("Has Disc", isOn: $viewModel.hasDisc)
                        .disabled(viewModel.isDigital)
                    Toggle("Has Box", isOn: $viewModel.hasBox)
                        .disabled(viewModel.isDigital)
                    Toggle("Has Manual", isOn: $viewModel.hasManual)
                        .disabled(viewModel.isDigital)
                    Toggle("Has Extras", isOn: $viewModel.hasExtras)
                        .disabled(viewModel.isDigital)
                    Toggle("Sealed", isOn: $viewModel.isSealed)
                        .disabled(viewModel.isDigital)
                }

                Section {
                    TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button {
                        Task {
                            let success = await viewModel.addToCollection(gameId: gameId)
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Add to Collection")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading || !isFormValid)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(gameTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await platformsViewModel.fetchPlatforms()
                await versionsViewModel.fetchVersions(forGameId: gameId)
                autoSelectVersion()
            }
            .onChange(of: viewModel.platformId) { _, _ in
                if let versionId = viewModel.gameVersionId,
                   !filteredVersions.contains(where: { $0.id == versionId }) {
                    viewModel.gameVersionId = nil
                }
                autoSelectVersion()
            }
            .onChange(of: viewModel.gameVersionId) { _, _ in
                if isDigitalOnlyVersion {
                    viewModel.isDigital = true
                }
            }
        }
    }
}

// MARK: - Quick Add to Library Sheet

struct QuickAddToLibrarySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStatus: GameStatus = .BACKLOG
    @State private var isLoading = false
    @State private var errorMessage: String?

    let gameId: String
    let gameTitle: String

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(GameStatus.allCases, id: \.self) { status in
                            Label(status.displayName, systemImage: status.iconName)
                                .tag(status)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Button {
                        Task {
                            await addToLibrary()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Add to Library")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoading)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(gameTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addToLibrary() async {
        isLoading = true
        errorMessage = nil

        let mutation = """
        mutation SetGameStatus($gameId: ID!, $status: GameStatus!) {
            setGameStatus(gameId: $gameId, status: $status) {
                success
            }
        }
        """

        do {
            let response: SetGameStatusResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["gameId": gameId, "status": selectedStatus.rawValue]
            )
            if response.setGameStatus.success {
                dismiss()
            } else {
                errorMessage = "Failed to add to library"
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
