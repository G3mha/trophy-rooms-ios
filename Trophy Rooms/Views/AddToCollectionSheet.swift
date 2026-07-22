import SwiftUI
import Combine
import ClerkKit

struct AddToCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddToCollectionViewModel()
    @StateObject private var platformsViewModel = PlatformsViewModel.shared
    @State private var internalEditingItem: CollectionItem?

    let gameId: String
    let gameTitle: String
    let existingItems: [CollectionItem]
    let editingItem: CollectionItem?
    let versions: [GameVersion]
    let gamePlatform: Platform?
    let onSave: () -> Void

    var isEditing: Bool { editingItem != nil || internalEditingItem != nil }
    var activeEditingItem: CollectionItem? { editingItem ?? internalEditingItem }

    /// If a specific game platform was provided, only show that platform
    var availablePlatforms: [Platform] {
        if let gamePlatform = gamePlatform {
            return [gamePlatform]
        }
        return platformsViewModel.platforms
    }

    /// Filter versions based on selected platform
    var filteredVersions: [GameVersion] {
        guard let platformId = viewModel.platformId else {
            return versions
        }
        return versions.filter { version in
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

    init(gameId: String, gameTitle: String, existingItems: [CollectionItem] = [], editingItem: CollectionItem? = nil, versions: [GameVersion] = [], gamePlatform: Platform? = nil, onSave: @escaping () -> Void) {
        self.gameId = gameId
        self.gameTitle = gameTitle
        self.existingItems = existingItems
        self.editingItem = editingItem
        self.versions = versions
        self.gamePlatform = gamePlatform
        self.onSave = onSave
    }

    /// Auto-select version: single version gets auto-selected, otherwise select the default
    private func autoSelectVersion() {
        // Don't auto-select if editing an existing item (already has version set)
        if editingItem != nil || internalEditingItem != nil {
            return
        }
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
                // Existing collection items (hidden when editing via external editingItem)
                if editingItem == nil && !existingItems.isEmpty {
                    Section(internalEditingItem != nil ? "Editing" : "In Your Collection") {
                        ForEach(existingItems) { item in
                            Button {
                                internalEditingItem = item
                                viewModel.populateFromItem(item)
                            } label: {
                                HStack {
                                    CollectionItemSummaryRow(item: item)
                                    Spacer()
                                    if internalEditingItem?.id == item.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "pencil.circle")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let item = existingItems[index]
                                Task {
                                    _ = await viewModel.removeFromCollection(id: item.id)
                                    onSave()
                                }
                            }
                        }
                    }
                }

                // Add/Edit item form
                Section {
                    if internalEditingItem != nil {
                        Button {
                            internalEditingItem = nil
                            viewModel.resetToDefaults()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add New Copy Instead")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text(isEditing ? "Edit Copy" : "Add New Copy")
                }

                Section {
                    // Platform (only show picker if multiple platforms available)
                    if availablePlatforms.count > 1 {
                        Picker("Platform", selection: $viewModel.platformId) {
                            Text("No Platform").tag(nil as String?)
                            ForEach(availablePlatforms) { platform in
                                Text(platform.name).tag(platform.id as String?)
                            }
                        }
                    } else if let platform = availablePlatforms.first {
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

                    // Version (required - always show)
                    if filteredVersions.isEmpty {
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
                    if filteredVersions.isEmpty {
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

                // Library section (only when adding, not editing)
                if !isEditing {
                    Section {
                        Toggle("Also add to Library", isOn: $viewModel.addToLibrary)
                    } footer: {
                        Text("Adds this game to your library as Backlog. If you already track it, nothing changes.")
                    }
                }

                Section {
                    Button {
                        Task {
                            let success: Bool
                            if let item = activeEditingItem {
                                success = await viewModel.updateCollectionItem(id: item.id)
                            } else {
                                success = await viewModel.addToCollection(gameId: gameId)
                            }
                            if success {
                                onSave()
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text(isEditing ? "Save Changes" : "Add to Collection")
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await platformsViewModel.fetchPlatforms()
                if let item = editingItem {
                    viewModel.populateFromItem(item)
                } else if let platform = gamePlatform {
                    // Pre-select the game's platform for new collection items
                    viewModel.platformId = platform.id
                }
                // Auto-select version for new items
                autoSelectVersion()
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

private struct CollectionItemSummaryRow: View {
    let item: CollectionItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.region.displayName)
                    .font(.headline)
                if item.isDigital == true {
                    Text("Digital")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.2))
                        .foregroundColor(.cyan)
                        .cornerRadius(4)
                }
                if let version = item.gameVersion {
                    Text(version.name)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                if item.isSealed {
                    Text("Sealed")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }
                if item.isComplete {
                    Text("Complete")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }

            HStack(spacing: 8) {
                if item.hasDisc {
                    Label("Disc", systemImage: "opticaldisc")
                        .font(.caption)
                }
                if item.hasBox {
                    Label("Box", systemImage: "shippingbox")
                        .font(.caption)
                }
                if item.hasManual {
                    Label("Manual", systemImage: "book.closed")
                        .font(.caption)
                }
                if item.hasExtras {
                    Label("Extras", systemImage: "gift")
                        .font(.caption)
                }
            }
            .foregroundColor(.secondary)

            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

class AddToCollectionViewModel: ObservableObject {
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
    @Published var addToLibrary = true
    @Published var isLoading = false
    @Published var errorMessage: String?

    func addToCollection(gameId: String) async -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let mutation = """
        mutation AddToCollection($input: AddToCollectionInput!) {
            addToCollection(input: $input) {
                success
                collectionItem {
                    id
                }
            }
        }
        """

        var input: [String: Any] = [
            "gameId": gameId,
            "isDigital": isDigital,
            "hasDisc": isDigital ? false : hasDisc,
            "hasBox": isDigital ? false : hasBox,
            "hasManual": isDigital ? false : hasManual,
            "hasExtras": isDigital ? false : hasExtras,
            "isSealed": isDigital ? false : isSealed,
            "region": region.rawValue,
            "notes": notes.isEmpty ? NSNull() : notes,
            "addToLibrary": addToLibrary
        ]
        if let platformId = platformId {
            input["platformId"] = platformId
        }
        if let gameVersionId = gameVersionId {
            input["gameVersionId"] = gameVersionId
        }

        do {
            let response: AddToCollectionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["input": input]
            )
            if response.addToCollection.success && addToLibrary {
                await CacheInvalidation.forLibraryChange()
            }
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return response.addToCollection.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }

    func removeFromCollection(id: String) async -> Bool {
        let mutation = """
        mutation RemoveFromCollection($id: ID!) {
            removeFromCollection(id: $id) {
                success
            }
        }
        """

        do {
            let response: RemoveFromCollectionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            return response.removeFromCollection.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func updateCollectionItem(id: String) async -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let mutation = """
        mutation UpdateCollectionItem($id: ID!, $input: UpdateCollectionItemInput!) {
            updateCollectionItem(id: $id, input: $input) {
                success
                collectionItem {
                    id
                }
            }
        }
        """

        var input: [String: Any] = [
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
            let response: UpdateCollectionItemResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id, "input": input]
            )
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return response.updateCollectionItem.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }

    func populateFromItem(_ item: CollectionItem) {
        region = item.region
        platformId = item.platform?.id
        gameVersionId = item.gameVersionId
        isDigital = item.isDigital ?? false
        hasDisc = item.hasDisc
        hasBox = item.hasBox
        hasManual = item.hasManual
        hasExtras = item.hasExtras
        isSealed = item.isSealed
        notes = item.notes ?? ""
    }

    func resetToDefaults() {
        region = .NTSC_U
        platformId = nil
        gameVersionId = nil
        isDigital = false
        hasDisc = true
        hasBox = true
        hasManual = true
        hasExtras = false
        isSealed = false
        notes = ""
    }
}
