import SwiftUI

struct AdminGameVersionFormSheet: View {
    @ObservedObject var viewModel: AdminGameVersionsViewModel
    let gameFamilyId: String
    let version: GameVersion?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var slug: String = ""
    @State private var description: String = ""
    @State private var coverUrl: String = ""
    @State private var selectedDlcIds: [String] = []
    @State private var selectedGameIds: Set<String> = []
    @State private var isDefault: Bool = false
    @State private var isSaving = false
    @State private var availableDlcs: [DLC] = []
    @State private var availableGames: [FamilyGame] = []
    @State private var isLoadingDlcs = false
    @State private var isLoadingGames = false

    var isEditing: Bool {
        version != nil
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !slug.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedGameIds.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Slug", text: $slug)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Version Details")
                } footer: {
                    Text("Examples: Standard, Deluxe Edition, Game of the Year Edition")
                }

                // Platform/Game Selection
                Section {
                    if isLoadingGames {
                        ProgressView("Loading platforms...")
                    } else if availableGames.isEmpty {
                        Text("No platform versions available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(availableGames, id: \.id) { game in
                            HStack {
                                if let platform = game.platform {
                                    PlatformIcon(slug: platform.slug ?? "", size: 20)
                                }
                                VStack(alignment: .leading) {
                                    Text(game.platform?.name ?? "Unknown Platform")
                                    if let platformSlug = game.platform?.slug {
                                        Text(platformSlug)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if selectedGameIds.contains(game.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.gray)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedGameIds.contains(game.id) {
                                    selectedGameIds.remove(game.id)
                                } else {
                                    selectedGameIds.insert(game.id)
                                }
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("Available On")
                        Spacer()
                        if !availableGames.isEmpty {
                            Text("\(selectedGameIds.count) selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Select which platforms this version is available on")
                }

                Section {
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Description")
                }

                Section {
                    TextField("Cover URL (optional)", text: $coverUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("Cover Image")
                } footer: {
                    Text("Leave empty to use the game's cover image")
                }

                Section {
                    if isLoadingDlcs {
                        ProgressView("Loading DLCs...")
                    } else if availableDlcs.isEmpty {
                        Text("No DLCs available for this game")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(availableDlcs, id: \.id) { dlc in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(dlc.name)
                                    Text(dlc.type.displayName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedDlcIds.contains(dlc.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedDlcIds.contains(dlc.id) {
                                    selectedDlcIds.removeAll { $0 == dlc.id }
                                } else {
                                    selectedDlcIds.append(dlc.id)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Included DLC")
                } footer: {
                    if !availableDlcs.isEmpty {
                        Text("Tap to select DLCs included in this version")
                    }
                }

                if !isEditing {
                    Section {
                        Toggle("Set as Default", isOn: $isDefault)
                    } header: {
                        Text("Default Version")
                    } footer: {
                        Text("The default version is selected automatically when users add this game to their library")
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Version" : "New Version")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        save()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
        .onAppear {
            if let version = version {
                name = version.name
                slug = version.slug ?? ""
                description = version.description ?? ""
                coverUrl = version.coverUrl ?? ""
                selectedDlcIds = version.dlcs?.map { $0.id } ?? []
                isDefault = version.isDefault
                // Pre-select games that this version is already linked to
                if let games = version.games {
                    selectedGameIds = Set(games.map { $0.id })
                }
            }
        }
        .task {
            await fetchGames()
            await fetchDlcs()
        }
    }

    private func fetchGames() async {
        isLoadingGames = true
        let query = """
        query GetGameFamilyGames($id: ID!) {
            gameFamily(id: $id) {
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
        """

        do {
            let response: GameFamilyGamesResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["id": gameFamilyId]
            )
            DispatchQueue.main.async {
                self.availableGames = response.gameFamily?.games ?? []
                self.isLoadingGames = false

                // If creating new and no games selected, select all by default
                if !isEditing && selectedGameIds.isEmpty {
                    selectedGameIds = Set(availableGames.map { $0.id })
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoadingGames = false
            }
        }
    }

    private func fetchDlcs() async {
        isLoadingDlcs = true
        let query = """
        query GetDLCs($gameFamilyId: ID!) {
            dlcs(gameFamilyId: $gameFamilyId) {
                id
                name
                slug
                type
            }
        }
        """

        do {
            let response: DLCsResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["gameFamilyId": gameFamilyId]
            )
            DispatchQueue.main.async {
                self.availableDlcs = response.dlcs
                self.isLoadingDlcs = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoadingDlcs = false
            }
        }
    }

    private func save() {
        isSaving = true

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedSlug = slug.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = description.trimmingCharacters(in: .whitespaces)
        let trimmedCoverUrl = coverUrl.trimmingCharacters(in: .whitespaces)

        let dlcIds: [String]? = selectedDlcIds.isEmpty ? nil : selectedDlcIds
        let gameIds = Array(selectedGameIds)

        Task {
            let success: Bool
            if let version = version {
                success = await viewModel.updateVersion(
                    id: version.id,
                    gameIds: gameIds,
                    name: trimmedName,
                    slug: trimmedSlug,
                    description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                    coverUrl: trimmedCoverUrl.isEmpty ? nil : trimmedCoverUrl,
                    dlcIds: dlcIds
                )
            } else {
                success = await viewModel.createVersion(
                    gameIds: gameIds,
                    name: trimmedName,
                    slug: trimmedSlug,
                    description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                    coverUrl: trimmedCoverUrl.isEmpty ? nil : trimmedCoverUrl,
                    dlcIds: dlcIds,
                    isDefault: isDefault
                )
            }

            DispatchQueue.main.async {
                isSaving = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Response Models

private struct GameFamilyGamesResponse: Decodable {
    let gameFamily: GameFamilyWithGames?
}

private struct GameFamilyWithGames: Decodable {
    let games: [FamilyGame]
}

struct FamilyGame: Identifiable, Decodable {
    let id: String
    let platform: Platform?
}

#Preview {
    AdminGameVersionFormSheet(
        viewModel: AdminGameVersionsViewModel(),
        gameFamilyId: "test-family-id",
        version: nil
    )
}
