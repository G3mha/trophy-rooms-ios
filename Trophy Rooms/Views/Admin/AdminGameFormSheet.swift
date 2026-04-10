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
    @State private var selectedBaseGames: [GameSummary] = []
    @State private var isSaving = false

    var isEditing: Bool {
        game != nil
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedPlatformId.isEmpty
    }

    var excludedGameIds: Set<String> {
        game.map { Set([$0.id]) } ?? []
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
                        MultiGameSelectorField(
                            title: "Base Games",
                            selectedGameIds: $selectedBaseGameIds,
                            selectedGames: $selectedBaseGames,
                            excludedGameIds: excludedGameIds
                        )
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

                // Restore base game families if editing a derivative
                if let baseGameFamilyIds = game.baseGameFamilyIds {
                    selectedBaseGameIds = Set(baseGameFamilyIds)
                } else if let baseGameFamilyId = game.baseGameFamilyId {
                    selectedBaseGameIds = Set([baseGameFamilyId])
                }
            } else if selectedPlatformId.isEmpty, let firstPlatform = viewModel.platforms.first {
                selectedPlatformId = firstPlatform.id
            }
        }
        .onChange(of: selectedType) { _, newValue in
            // Clear base games if switching to BASE_GAME type
            if newValue == .BASE_GAME {
                selectedBaseGameIds.removeAll()
                selectedBaseGames.removeAll()
            }
        }
    }

    private func save() {
        isSaving = true

        Task {
            let success: Bool
            let desc = description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description.trimmingCharacters(in: .whitespaces)
            let cover = coverUrl.trimmingCharacters(in: .whitespaces).isEmpty ? nil : coverUrl.trimmingCharacters(in: .whitespaces)
            let baseGameFamilyIds = selectedBaseGameIds.isEmpty ? nil : Array(selectedBaseGameIds)

            if let game = game {
                success = await viewModel.updateGame(
                    id: game.id,
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: desc,
                    coverUrl: cover,
                    platformId: selectedPlatformId,
                    type: selectedType,
                    baseGameFamilyIds: baseGameFamilyIds
                )
            } else {
                success = await viewModel.createGame(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: desc,
                    coverUrl: cover,
                    platformId: selectedPlatformId,
                    type: selectedType,
                    baseGameFamilyIds: baseGameFamilyIds
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
