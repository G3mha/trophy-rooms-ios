import SwiftUI

struct AdminSetFormSheet: View {
    @ObservedObject var viewModel: AdminAchievementSetsViewModel
    let achievementSet: AdminAchievementSet?
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedType: AchievementSetType = .OFFICIAL
    @State private var selectedVisibility: AchievementSetVisibility = .PUBLIC
    @State private var selectedGameId: String = ""
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
                } header: {
                    Text("Game")
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
            } else if selectedGameId.isEmpty, let firstGame = viewModel.games.first {
                selectedGameId = firstGame.id
            }
        }
    }

    private func save() {
        isSaving = true

        Task {
            let success: Bool
            if let set = achievementSet {
                success = await viewModel.updateAchievementSet(
                    id: set.id,
                    title: title.trimmingCharacters(in: .whitespaces),
                    type: selectedType,
                    visibility: selectedVisibility,
                    gameId: selectedGameId
                )
            } else {
                success = await viewModel.createAchievementSet(
                    title: title.trimmingCharacters(in: .whitespaces),
                    type: selectedType,
                    visibility: selectedVisibility,
                    gameId: selectedGameId
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
