import SwiftUI

struct AdminSetFormSheet: View {
    @ObservedObject var viewModel: AdminAchievementSetsViewModel
    let achievementSet: AdminAchievementSet?
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedType: AchievementSetType = .OFFICIAL
    @State private var selectedVisibility: AchievementSetVisibility = .PUBLIC
    @State private var selectedGame: GameSummary?
    @State private var selectedVersionId: String = ""
    @State private var selectedDlcId: String = ""
    @State private var isSaving = false

    var isEditing: Bool {
        achievementSet != nil
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        selectedGame != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)

                    Picker("Type", selection: $selectedType) {
                        ForEach(AchievementSetType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    Picker("Visibility", selection: $selectedVisibility) {
                        ForEach(AchievementSetVisibility.allCases, id: \.self) { visibility in
                            Text(visibility.displayName).tag(visibility)
                        }
                    }
                } header: {
                    Text("Set Details")
                }

                Section {
                    GameSelectorField(
                        title: "Game",
                        selectedGame: $selectedGame
                    )
                    .onChange(of: selectedGame) { _, newValue in
                        selectedVersionId = ""
                        selectedDlcId = ""
                        if let game = newValue {
                            Task {
                                await viewModel.fetchVersions(gameId: game.id)
                                await viewModel.fetchDlcs(gameId: game.id)
                            }
                        } else {
                            viewModel.versions = []
                            viewModel.dlcs = []
                        }
                    }
                } header: {
                    Text("Game")
                }

                if selectedGame != nil && viewModel.versions.count > 1 {
                    Section {
                        Picker("Version", selection: $selectedVersionId) {
                            Text("All Versions").tag("")
                            ForEach(viewModel.versions, id: \.id) { version in
                                HStack {
                                    Text(version.name)
                                    if version.isDefault {
                                        Text("(Default)")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(version.id)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    } header: {
                        Text("Version (Optional)")
                    } footer: {
                        Text("Select a specific version or leave as 'All Versions' to apply to the entire game")
                    }
                }

                if selectedGame != nil && !viewModel.dlcs.isEmpty {
                    Section {
                        Picker("DLC", selection: $selectedDlcId) {
                            Text("Base Game").tag("")
                            ForEach(viewModel.dlcs, id: \.id) { dlc in
                                HStack {
                                    Text(dlc.name)
                                    Text("(\(dlc.type.displayName))")
                                        .foregroundStyle(.secondary)
                                }
                                .tag(dlc.id)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    } header: {
                        Text("DLC (Optional)")
                    } footer: {
                        Text("Select a DLC if this achievement set belongs to specific downloadable content")
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Set" : "New Set")
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
            if let set = achievementSet {
                title = set.title
                selectedType = set.typeEnum
                selectedVisibility = set.visibilityEnum
                selectedVersionId = set.gameVersionId ?? ""
                selectedDlcId = set.dlcId ?? ""

                // Create a GameSummary from the set's game info
                if let gameInfo = set.game {
                    selectedGame = GameSummary(
                        id: gameInfo.id,
                        title: gameInfo.title,
                        description: nil,
                        coverUrl: nil,
                        type: nil,
                        baseGameId: nil,
                        platform: nil,
                        achievementSetCount: 0,
                        achievementCount: 0,
                        trophyCount: 0
                    )
                    Task {
                        await viewModel.fetchVersions(gameId: gameInfo.id)
                        await viewModel.fetchDlcs(gameId: gameInfo.id)
                    }
                }
            }
        }
    }

    private func save() {
        guard let game = selectedGame else { return }

        isSaving = true

        Task {
            let success: Bool
            let versionId = selectedVersionId.isEmpty ? nil : selectedVersionId
            let dlcId = selectedDlcId.isEmpty ? nil : selectedDlcId

            if let set = achievementSet {
                success = await viewModel.updateAchievementSet(
                    id: set.id,
                    title: title.trimmingCharacters(in: .whitespaces),
                    type: selectedType,
                    visibility: selectedVisibility,
                    gameId: game.id,
                    gameVersionId: versionId,
                    dlcId: dlcId
                )
            } else {
                success = await viewModel.createAchievementSet(
                    title: title.trimmingCharacters(in: .whitespaces),
                    type: selectedType,
                    visibility: selectedVisibility,
                    gameId: game.id,
                    gameVersionId: versionId,
                    dlcId: dlcId
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

#Preview {
    AdminSetFormSheet(viewModel: AdminAchievementSetsViewModel(), achievementSet: nil)
}
