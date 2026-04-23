import SwiftUI

struct AdminGameIdentitySection: View {
    @Binding var title: String
    @Binding var selectedType: GameType

    var body: some View {
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
    }
}

struct AdminGameIGDBImportSection: View {
    @Binding var igdbUrl: String
    let isImporting: Bool
    let onImport: () -> Void

    var body: some View {
        Section {
            URLTextField("IGDB Game URL", text: $igdbUrl)

            Button {
                onImport()
            } label: {
                HStack {
                    if isImporting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "sparkles.rectangle.stack")
                    }
                    Text(isImporting ? "Importing..." : "Import From IGDB")
                }
            }
            .disabled(igdbUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isImporting)
        } header: {
            Text("Import")
        } footer: {
            Text("Paste an IGDB game URL to create the game family automatically from IGDB metadata and mapped platforms.")
        }
    }
}

struct AdminGamePlatformsSection: View {
    let platforms: [AdminPlatform]
    @Binding var selectedPlatformIds: Set<String>
    let isEditing: Bool

    var body: some View {
        Section {
            PlatformSelectionField(
                platforms: platforms,
                selectedPlatformIds: $selectedPlatformIds,
                allowsMultipleSelection: !isEditing,
                isDisabled: isEditing
            )
        } header: {
            Text("Platforms")
        } footer: {
            if isEditing {
                Text("Platform cannot be changed when editing. Use clone to add platforms or remove this platform if it was created by mistake.")
            } else {
                Text("Select one or more platforms for this game.")
            }
        }
    }
}

struct AdminGameBaseGamesSection: View {
    let selectedType: GameType
    @Binding var selectedBaseGameIds: Set<String>
    @Binding var selectedBaseGames: [GameSummary]
    let excludedGameIds: Set<String>

    var body: some View {
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
    }
}

struct AdminGameOptionalMetadataSection: View {
    @Binding var description: String
    @Binding var coverUrl: String

    var body: some View {
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
    }
}

struct AdminGameCoverPreviewSection: View {
    let coverUrl: String

    var body: some View {
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
    }
}

struct AdminGameErrorSection: View {
    let error: String

    var body: some View {
        Section {
            Text(error)
                .foregroundStyle(.red)
        }
    }
}

struct AdminGameFamilyActionsSection: View {
    let game: AdminGameItem
    let isSaving: Bool
    let onRemove: () -> Void

    var body: some View {
        Section {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label(
                    game.platformName.map { "Remove \($0) From Family" } ?? "Remove Platform From Family",
                    systemImage: "minus.circle"
                )
            }
            .disabled(isSaving)
        } footer: {
            Text("This removes only the current platform entry from the game family. Any achievement sets and achievements attached to this platform will also be deleted.")
        }
    }
}
