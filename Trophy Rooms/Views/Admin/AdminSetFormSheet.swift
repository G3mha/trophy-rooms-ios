import SwiftUI

struct AdminSetFormSheet: View {
    @ObservedObject var viewModel: AdminAchievementSetsViewModel
    let achievementSet: AdminAchievementSet?
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedType: AchievementSetType = .OFFICIAL
    @State private var selectedVisibility: AchievementSetVisibility = .PUBLIC
    @State private var selectedGameId: String = ""
    @State private var selectedVersionId: String = ""
    @State private var selectedDlcId: String = ""
    @State private var gameSearchText: String = ""
    @State private var isSaving = false

    var isEditing: Bool {
        achievementSet != nil
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedGameId.isEmpty
    }

    var filteredGames: [AdminGame] {
        if gameSearchText.isEmpty {
            return viewModel.games
        }
        return viewModel.games.filter { game in
            game.title.localizedCaseInsensitiveContains(gameSearchText)
        }
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
                    Picker("Game", selection: $selectedGameId) {
                        Text("Select Game").tag("")
                        ForEach(filteredGames) { game in
                            Text(game.title).tag(game.id)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: selectedGameId) { _, newValue in
                        selectedVersionId = ""
                        selectedDlcId = ""
                        if !newValue.isEmpty {
                            Task {
                                await viewModel.fetchVersions(gameId: newValue)
                                await viewModel.fetchDlcs(gameId: newValue)
                            }
                        } else {
                            viewModel.versions = []
                            viewModel.dlcs = []
                        }
                    }
                } header: {
                    Text("Game")
                }

                if !selectedGameId.isEmpty && viewModel.versions.count > 1 {
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

                if !selectedGameId.isEmpty && !viewModel.dlcs.isEmpty {
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
                selectedGameId = set.game?.id ?? ""
                selectedVersionId = set.gameVersionId ?? ""
                selectedDlcId = set.dlcId ?? ""
                if !selectedGameId.isEmpty {
                    Task {
                        await viewModel.fetchVersions(gameId: selectedGameId)
                        await viewModel.fetchDlcs(gameId: selectedGameId)
                    }
                }
            } else if selectedGameId.isEmpty, let firstGame = viewModel.games.first {
                selectedGameId = firstGame.id
                Task {
                    await viewModel.fetchVersions(gameId: firstGame.id)
                    await viewModel.fetchDlcs(gameId: firstGame.id)
                }
            }
        }
    }

    private func save() {
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
                    gameId: selectedGameId,
                    gameVersionId: versionId,
                    dlcId: dlcId
                )
            } else {
                success = await viewModel.createAchievementSet(
                    title: title.trimmingCharacters(in: .whitespaces),
                    type: selectedType,
                    visibility: selectedVisibility,
                    gameId: selectedGameId,
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
