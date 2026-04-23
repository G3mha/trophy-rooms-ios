import SwiftUI

struct AdminSetDetailsSection: View {
    @Binding var title: String
    @Binding var selectedType: AchievementSetType
    @Binding var selectedVisibility: AchievementSetVisibility

    var body: some View {
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
    }
}

struct AdminSetGameSection: View {
    @Binding var selectedGame: GameSummary?

    var body: some View {
        Section {
            GameSelectorField(
                title: "Game",
                selectedGame: $selectedGame
            )
        } header: {
            Text("Game")
        }
    }
}

struct AdminSetVersionSection: View {
    let selectedGame: GameSummary?
    let versions: [GameVersion]
    @Binding var selectedVersionId: String

    var body: some View {
        if selectedGame != nil && versions.count > 1 {
            Section {
                Picker("Version", selection: $selectedVersionId) {
                    Text("All Versions").tag("")
                    ForEach(versions, id: \.id) { version in
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
    }
}

struct AdminSetDLCSection: View {
    let selectedGame: GameSummary?
    let dlcs: [DLC]
    @Binding var selectedDlcId: String

    var body: some View {
        if selectedGame != nil && !dlcs.isEmpty {
            Section {
                Picker("DLC", selection: $selectedDlcId) {
                    Text("Base Game").tag("")
                    ForEach(dlcs, id: \.id) { dlc in
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
    }
}

struct AdminSetErrorSection: View {
    let error: String

    var body: some View {
        Section {
            Text(error)
                .foregroundStyle(.red)
        }
    }
}
