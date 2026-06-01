import SwiftUI
import Combine
import ClerkKit

struct ConvertToCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ConvertToCollectionViewModel()
    @StateObject private var platformsViewModel = PlatformsViewModel.shared
    @StateObject private var versionsViewModel = GameVersionsViewModel()

    let buylistItem: BuylistItem
    let onConvert: () -> Void

    /// Filter versions based on selected platform
    var filteredVersions: [GameVersion] {
        guard let platformId = viewModel.platformId else {
            return versionsViewModel.versions
        }
        return versionsViewModel.versions.filter { version in
            guard let games = version.games else { return true }
            return games.contains { $0.platform?.id == platformId }
        }
    }

    /// Get the currently selected version
    var selectedVersion: GameVersion? {
        guard let versionId = viewModel.gameVersionId else { return nil }
        return filteredVersions.first { $0.id == versionId }
    }

    /// Check if the selected version is digital only
    var isDigitalOnlyVersion: Bool {
        selectedVersion?.digitalOnly ?? false
    }

    /// Check if form is valid for submission
    var isFormValid: Bool {
        viewModel.gameVersionId != nil
    }

    /// Auto-select version: single version gets auto-selected, otherwise select the default
    private func autoSelectVersion() {
        // Don't override if already selected
        if viewModel.gameVersionId != nil {
            return
        }
        if filteredVersions.count == 1 {
            // Single version - auto-select it
            viewModel.gameVersionId = filteredVersions[0].id
        } else if let defaultVersion = filteredVersions.first(where: { $0.isDefault }) {
            // Multiple versions - select the default one
            viewModel.gameVersionId = defaultVersion.id
        } else if let firstVersion = filteredVersions.first {
            // No default - select the first one
            viewModel.gameVersionId = firstVersion.id
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Item info section
                Section {
                    HStack(spacing: 12) {
                        CoverImage(
                            url: buylistItem.displayCoverUrl,
                            width: 60,
                            height: 80,
                            placeholderIcon: "gamecontroller"
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(buylistItem.displayTitle)
                                .font(.headline)
                                .lineLimit(2)

                            if let platform = buylistItem.displayPlatform {
                                HStack(spacing: 4) {
                                    if let slug = platform.slug {
                                        PlatformIcon(slug: slug, size: 14)
                                    }
                                    Text(platform.name)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Section {
                    // Platform picker
                    if platformsViewModel.platforms.count > 1 {
                        Picker("Platform", selection: $viewModel.platformId) {
                            Text("No Platform").tag(nil as String?)
                            ForEach(platformsViewModel.platforms) { platform in
                                Text(platform.name).tag(platform.id as String?)
                            }
                        }
                    } else if let platform = platformsViewModel.platforms.first {
                        // Single platform - show as read-only
                        HStack {
                            Text("Platform")
                            Spacer()
                            if let slug = platform.slug {
                                PlatformIcon(slug: slug, size: 16)
                            }
                            Text(platform.name)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Version picker (required)
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
                        // Single version - show as read-only (auto-selected)
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(filteredVersions[0].name)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Picker("Version", selection: $viewModel.gameVersionId) {
                            ForEach(filteredVersions, id: \.id) { version in
                                HStack {
                                    Text(version.name)
                                    if version.isDefault {
                                        Text("(Default)")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(version.id as String?)
                            }
                        }
                    }

                    // Region
                    Picker("Region", selection: $viewModel.region) {
                        ForEach(GameRegion.allCases, id: \.self) { region in
                            Text(region.displayName).tag(region)
                        }
                    }

                    // Digital copy toggle (forced on for digital-only versions)
                    Toggle("Digital Copy", isOn: $viewModel.isDigital)
                        .disabled(isDigitalOnlyVersion)
                } footer: {
                    if filteredVersions.isEmpty && !versionsViewModel.isLoading {
                        Text("This game cannot be added to your collection because no versions are available for this platform.")
                            .foregroundStyle(.red)
                    } else if isDigitalOnlyVersion {
                        Text("This version is only available as a digital copy.")
                    }
                }

                // Physical condition section (disabled for digital copies)
                Section {
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
                } header: {
                    Text("Physical Condition")
                } footer: {
                    if viewModel.isDigital {
                        Text("Physical condition options are not applicable for digital copies.")
                    }
                }

                // Notes section
                Section {
                    TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button {
                        Task {
                            let success = await viewModel.convertToCollection(buylistItemId: buylistItem.id)
                            if success {
                                onConvert()
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
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await platformsViewModel.fetchPlatforms()

                // Pre-select platform from buylist item
                if let platform = buylistItem.displayPlatform {
                    viewModel.platformId = platform.id
                }

                // Pre-fill version from buylist item
                if let versionId = buylistItem.gameVersionId {
                    viewModel.gameVersionId = versionId
                }

                // Pre-fill notes from buylist item
                if let notes = buylistItem.notes {
                    viewModel.notes = notes
                }

                // Fetch versions for this game
                if let gameId = buylistItem.gameId {
                    await versionsViewModel.fetchVersions(forGameId: gameId)
                    // Auto-select version after fetching
                    autoSelectVersion()
                }
            }
            .onChange(of: viewModel.platformId) { _, _ in
                // Clear version if it's no longer available for the selected platform
                if let versionId = viewModel.gameVersionId,
                   !filteredVersions.contains(where: { $0.id == versionId }) {
                    viewModel.gameVersionId = nil
                }
                // Auto-select version when platform changes
                autoSelectVersion()
            }
            .onChange(of: viewModel.gameVersionId) { _, _ in
                // Enforce isDigital when digital-only version is selected
                if isDigitalOnlyVersion {
                    viewModel.isDigital = true
                }
            }
        }
    }
}

class ConvertToCollectionViewModel: ObservableObject {
    @Published var region: GameRegion = .NTSC_U
    @Published var platformId: String?
    @Published var gameVersionId: String?
    @Published var isDigital = false
    @Published var hasDisc = true
    @Published var hasBox = true
    @Published var hasManual = true
    @Published var hasExtras = false
    @Published var isSealed = false
    @Published var notes = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func convertToCollection(buylistItemId: String) async -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let mutation = """
        mutation ConvertBuylistToCollection($input: ConvertBuylistToCollectionInput!) {
            convertBuylistToCollection(input: $input) {
                success
                collectionItem {
                    id
                }
            }
        }
        """

        var input: [String: Any] = [
            "buylistItemId": buylistItemId,
            "isDigital": isDigital,
            "hasDisc": isDigital ? false : hasDisc,
            "hasBox": isDigital ? false : hasBox,
            "hasManual": isDigital ? false : hasManual,
            "hasExtras": isDigital ? false : hasExtras,
            "isSealed": isDigital ? false : isSealed,
            "region": region.rawValue,
            "notes": notes.isEmpty ? NSNull() : notes
        ]
        if let platformId = platformId {
            input["platformId"] = platformId
        }
        if let gameVersionId = gameVersionId {
            input["gameVersionId"] = gameVersionId
        }

        do {
            let response: ConvertBuylistToCollectionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["input": input]
            )
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return response.convertBuylistToCollection.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
}

class GameVersionsViewModel: ObservableObject {
    @Published var versions: [GameVersion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchVersions(forGameId gameId: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GameVersions($gameId: ID!) {
            game(id: $gameId) {
                versions {
                    id
                    name
                    slug
                    description
                    coverUrl
                    effectiveCoverUrl
                    releaseDate
                    isDefault
                    digitalOnly
                    games {
                        id
                        platform {
                            id
                            name
                            slug
                        }
                    }
                }
            }
        }
        """

        do {
            let response: GameVersionsForConvertResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["gameId": gameId]
            )
            DispatchQueue.main.async {
                self.versions = response.game?.versions ?? []
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

private struct GameVersionsForConvertResponse: Decodable {
    let game: GameWithVersions?
}

private struct GameWithVersions: Decodable {
    let versions: [GameVersion]?
}
