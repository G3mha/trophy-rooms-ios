import SwiftUI

struct AdminGameFormSheet: View {
    @ObservedObject var viewModel: AdminGamesViewModel
    let game: AdminGameItem?
    var onSave: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var coverUrl: String = ""
    @State private var selectedPlatformIds: Set<String> = []
    @State private var selectedType: GameType = .BASE_GAME
    @State private var selectedBaseGameIds: Set<String> = []
    @State private var selectedBaseGames: [GameSummary] = []
    @State private var isSaving = false

    var isEditing: Bool {
        game != nil
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedPlatformIds.isEmpty
    }

    var excludedGameIds: Set<String> {
        game.map { Set([$0.id]) } ?? []
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)

                    Picker("Type", selection: $selectedType) {
                        ForEach(GameType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                } header: {
                    Text("Game Details")
                }

                Section {
                    PlatformSelectionField(
                        platforms: viewModel.platforms,
                        selectedPlatformIds: $selectedPlatformIds,
                        allowsMultipleSelection: !isEditing,
                        isDisabled: isEditing
                    )
                } header: {
                    Text("Platforms")
                } footer: {
                    if isEditing {
                        Text("Platform cannot be changed when editing. Use clone to add to other platforms.")
                    } else {
                        Text("Select one or more platforms for this game.")
                    }
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
                        .lineLimit(2...8)
                        .frame(minHeight: 60, maxHeight: 150)

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
                if let platformId = game.platformId {
                    selectedPlatformIds = Set([platformId])
                }
                selectedType = game.type ?? .BASE_GAME

                // Restore base game families if editing a derivative
                if let baseGameFamilyIds = game.baseGameFamilyIds {
                    selectedBaseGameIds = Set(baseGameFamilyIds)
                } else if let baseGameFamilyId = game.baseGameFamilyId {
                    selectedBaseGameIds = Set([baseGameFamilyId])
                }

                // Populate selectedBaseGames for display from baseGameFamilies
                if let baseGameFamilies = game.baseGameFamilies {
                    selectedBaseGames = baseGameFamilies.map { family in
                        GameSummary(
                            id: family.id,
                            title: family.title,
                            coverUrl: family.coverUrl,
                            type: family.type
                        )
                    }
                }
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
                // When editing, use updateGame with single platformId
                success = await viewModel.updateGame(
                    id: game.id,
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: desc,
                    coverUrl: cover,
                    platformId: selectedPlatformIds.first ?? "",
                    type: selectedType,
                    baseGameFamilyIds: baseGameFamilyIds
                )
            } else {
                // When creating, use createGameFamily with multiple platformIds
                success = await viewModel.createGameFamily(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: desc,
                    coverUrl: cover,
                    platformIds: Array(selectedPlatformIds),
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
