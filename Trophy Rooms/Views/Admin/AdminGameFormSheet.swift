import SwiftUI

struct AdminGameFormSheet: View {
    @ObservedObject var viewModel: AdminGamesViewModel
    let game: AdminGameItem?
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var coverUrl: String = ""
    @State private var selectedPlatformId: String = ""
    @State private var selectedType: GameType = .BASE_GAME
    @State private var selectedBaseGameId: String?
    @State private var isShowingBaseGamePicker = false
    @State private var isSaving = false

    var isEditing: Bool {
        game != nil
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedPlatformId.isEmpty
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

                // Base Game picker (only for Fangames and ROM Hacks)
                if selectedType != .BASE_GAME {
                    Section {
                        Button {
                            isShowingBaseGamePicker = true
                        } label: {
                            HStack {
                                Text("Based On")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if let baseGameId = selectedBaseGameId,
                                   let baseGame = viewModel.baseGameForId(baseGameId) {
                                    Text(baseGame.title)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("None (Optional)")
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        if selectedBaseGameId != nil {
                            Button("Clear Base Game", role: .destructive) {
                                selectedBaseGameId = nil
                            }
                        }
                    } header: {
                        Text("Base Game")
                    } footer: {
                        Text("Link this \(selectedType == .FANGAME ? "fangame" : "ROM hack") to its original game")
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
                selectedBaseGameId = game.baseGameId
            } else if selectedPlatformId.isEmpty, let firstPlatform = viewModel.platforms.first {
                selectedPlatformId = firstPlatform.id
            }
        }
        .sheet(isPresented: $isShowingBaseGamePicker) {
            BaseGamePickerSheet(
                viewModel: viewModel,
                selectedGameId: $selectedBaseGameId,
                excludeGameId: game?.id
            )
        }
        .onChange(of: selectedType) { oldValue, newValue in
            // Clear base game if switching to BASE_GAME type
            if newValue == .BASE_GAME {
                selectedBaseGameId = nil
            }
        }
    }

    private func save() {
        isSaving = true

        Task {
            let success: Bool
            let desc = description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description.trimmingCharacters(in: .whitespaces)
            let cover = coverUrl.trimmingCharacters(in: .whitespaces).isEmpty ? nil : coverUrl.trimmingCharacters(in: .whitespaces)

            if let game = game {
                success = await viewModel.updateGame(
                    id: game.id,
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: desc,
                    coverUrl: cover,
                    platformId: selectedPlatformId,
                    type: selectedType,
                    baseGameId: selectedBaseGameId
                )
            } else {
                success = await viewModel.createGame(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: desc,
                    coverUrl: cover,
                    platformId: selectedPlatformId,
                    type: selectedType,
                    baseGameId: selectedBaseGameId
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

// MARK: - Base Game Picker Sheet

struct BaseGamePickerSheet: View {
    @ObservedObject var viewModel: AdminGamesViewModel
    @Binding var selectedGameId: String?
    let excludeGameId: String?
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredGames: [AdminGameItem] {
        var games = viewModel.games.filter { $0.id != excludeGameId }

        // Only show base games (not fangames/ROM hacks themselves)
        games = games.filter { $0.type == nil || $0.type == .BASE_GAME }

        if !searchText.isEmpty {
            games = games.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }

        return games
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredGames) { game in
                    Button {
                        selectedGameId = game.id
                        dismiss()
                    } label: {
                        HStack {
                            if let coverUrl = game.coverUrl, let url = URL(string: coverUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(.quaternary)
                                }
                                .frame(width: 40, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }

                            VStack(alignment: .leading) {
                                Text(game.title)
                                    .foregroundStyle(.primary)
                                if let platformName = game.platformName {
                                    Text(platformName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            if selectedGameId == game.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search base games")
            .navigationTitle("Select Base Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AdminGameFormSheet(viewModel: AdminGamesViewModel(), game: nil)
}
