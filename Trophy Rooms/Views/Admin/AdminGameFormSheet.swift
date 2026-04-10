import SwiftUI

struct AdminGameFormSheet: View {
    @ObservedObject var viewModel: AdminGamesViewModel
    let game: AdminGameItem?
    var onSave: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var coverUrl: String = ""
    @State private var selectedPlatformId: String = ""
    @State private var selectedType: GameType = .BASE_GAME
    @State private var selectedBaseGameIds: Set<String> = []
    @State private var isSaving = false
    @State private var baseGameSearchText: String = ""
    @State private var availableBaseGames: [GameSummary] = []
    @State private var isLoadingBaseGames = false

    var isEditing: Bool {
        game != nil
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedPlatformId.isEmpty
    }

    var filteredBaseGames: [GameSummary] {
        let excludedIds: Set<String> = game.map { Set([$0.id]) } ?? []
        let filtered = availableBaseGames.filter { !excludedIds.contains($0.id) }

        if baseGameSearchText.isEmpty {
            return filtered
        }
        return filtered.filter { $0.title.localizedCaseInsensitiveContains(baseGameSearchText) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)

                    Picker("Platform", selection: $selectedPlatformId) {
                        Text("Select Platform").tag("")
                        ForEach(viewModel.platforms) { platform in
                            Text(platform.name).tag(platform.id)
                        }
                    }

                    Picker("Type", selection: $selectedType) {
                        ForEach(GameType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                } header: {
                    Text("Game Details")
                }

                // Base Games picker (only for non-base game types)
                if selectedType != .BASE_GAME {
                    Section {
                        if isLoadingBaseGames {
                            ProgressView("Loading games...")
                        } else if availableBaseGames.isEmpty {
                            Text("No base games available")
                                .foregroundStyle(.secondary)
                        } else {
                            TextField("Search games", text: $baseGameSearchText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            ForEach(filteredBaseGames) { baseGame in
                                HStack {
                                    if let coverUrl = baseGame.coverUrl, let url = URL(string: coverUrl) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.gray.opacity(0.3)
                                        }
                                        .frame(width: 40, height: 56)
                                        .cornerRadius(4)
                                    } else {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 40, height: 56)
                                            .overlay {
                                                Image(systemName: "gamecontroller")
                                                    .font(.caption)
                                                    .foregroundStyle(.gray)
                                            }
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(baseGame.title)
                                            .font(.subheadline)
                                        if let platform = baseGame.platform {
                                            Text(platform.name)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if selectedBaseGameIds.contains(baseGame.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggleBaseGame(baseGame)
                                }
                            }
                        }
                    } header: {
                        HStack {
                            Text("Base Games")
                            Spacer()
                            if !selectedBaseGameIds.isEmpty {
                                Text("\(selectedBaseGameIds.count) selected")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } footer: {
                        Text("Select all platform versions this \(selectedType.displayName.lowercased()) is based on")
                    }
                }

                Section {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    TextField("Cover URL", text: $coverUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("Optional")
                }

                if !coverUrl.isEmpty, let url = URL(string: coverUrl) {
                    Section {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                    } header: {
                        Text("Cover Preview")
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Game" : "New Game")
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
            if let game = game {
                title = game.title
                description = game.description ?? ""
                coverUrl = game.coverUrl ?? ""
                selectedPlatformId = game.platformId ?? ""
                selectedType = game.type ?? .BASE_GAME

                // Restore base games if editing a derivative
                if let baseGameIds = game.baseGameIds {
                    selectedBaseGameIds = Set(baseGameIds)
                } else if let baseGameId = game.baseGameId {
                    selectedBaseGameIds = Set([baseGameId])
                }
            } else if selectedPlatformId.isEmpty, let firstPlatform = viewModel.platforms.first {
                selectedPlatformId = firstPlatform.id
            }
        }
        .task {
            await fetchBaseGames()
        }
        .onChange(of: selectedType) { oldValue, newValue in
            // Clear base games if switching to BASE_GAME type
            if newValue == .BASE_GAME {
                selectedBaseGameIds.removeAll()
            }
        }
    }

    private func toggleBaseGame(_ game: GameSummary) {
        if selectedBaseGameIds.contains(game.id) {
            selectedBaseGameIds.remove(game.id)
        } else {
            selectedBaseGameIds.insert(game.id)
        }
    }

    private func fetchBaseGames() async {
        isLoadingBaseGames = true

        let query = """
        query GetBaseGames {
            gamesPage(pageSize: 100, filter: { type: BASE_GAME }) {
                items {
                    id
                    title
                    coverUrl
                    type
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
            let response: GamesPageResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.availableBaseGames = response.gamesPage.items
                self.isLoadingBaseGames = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoadingBaseGames = false
            }
        }
    }

    private func save() {
        isSaving = true

        Task {
            let success: Bool
            let desc = description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description.trimmingCharacters(in: .whitespaces)
            let cover = coverUrl.trimmingCharacters(in: .whitespaces).isEmpty ? nil : coverUrl.trimmingCharacters(in: .whitespaces)
            let baseGameIds = selectedBaseGameIds.isEmpty ? nil : Array(selectedBaseGameIds)

            if let game = game {
                success = await viewModel.updateGame(
                    id: game.id,
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: desc,
                    coverUrl: cover,
                    platformId: selectedPlatformId,
                    type: selectedType,
                    baseGameIds: baseGameIds
                )
            } else {
                success = await viewModel.createGame(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: desc,
                    coverUrl: cover,
                    platformId: selectedPlatformId,
                    type: selectedType,
                    baseGameIds: baseGameIds
                )
            }

            DispatchQueue.main.async {
                isSaving = false
                if success {
                    onSave?()
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    AdminGameFormSheet(viewModel: AdminGamesViewModel(), game: nil)
}
