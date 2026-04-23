import SwiftUI

struct CloneGameSheet: View {
    @ObservedObject var viewModel: AdminGamesViewModel
    let game: AdminGameItem
    let onDismiss: () -> Void

    @State private var selectedPlatformIds: Set<String> = []
    @State private var copyAchievementSets = false
    @State private var isCloning = false

    var availablePlatforms: [AdminPlatform] {
        viewModel.platforms.filter { $0.id != game.platformId }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        AsyncImage(url: game.coverUrl.flatMap { URL(string: $0) }) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(game.title)
                                .font(.headline)
                            if let platformName = game.platformName {
                                Text("Current: \(platformName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Source Game")
                }

                Section {
                    PlatformSelectionField(
                        platforms: availablePlatforms,
                        selectedPlatformIds: $selectedPlatformIds,
                        allowsMultipleSelection: false,
                        isDisabled: false
                    )
                } header: {
                    Text("Clone To")
                }

                Section {
                    Toggle("Copy Achievement Sets", isOn: $copyAchievementSets)
                } footer: {
                    Text("If enabled, all achievement sets and their achievements will be copied to the new game.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Clone Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .disabled(isCloning)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clone") {
                        guard let platformId = selectedPlatformIds.first else { return }
                        Task {
                            isCloning = true
                            let success = await viewModel.cloneGameToPlatform(
                                gameId: game.id,
                                targetPlatformId: platformId,
                                copyAchievementSets: copyAchievementSets
                            )
                            isCloning = false
                            if success {
                                onDismiss()
                            }
                        }
                    }
                    .disabled(selectedPlatformIds.isEmpty || isCloning)
                }
            }
            .interactiveDismissDisabled(isCloning)
        }
        .presentationDetents([.medium])
    }
}

struct AddPlatformSheet: View {
    @ObservedObject var viewModel: AdminGamesViewModel
    let gameFamilyId: String
    let gameTitle: String
    let existingPlatformIds: Set<String>
    let onDismiss: () -> Void

    @State private var selectedPlatformIds: Set<String> = []
    @State private var isAdding = false

    var availablePlatforms: [AdminPlatform] {
        viewModel.platforms.filter { !existingPlatformIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(gameTitle)
                        .font(.headline)
                } header: {
                    Text("Game Family")
                }

                Section {
                    if availablePlatforms.isEmpty {
                        Text("All platforms already have this game")
                            .foregroundStyle(.secondary)
                    } else {
                        PlatformSelectionField(
                            platforms: availablePlatforms,
                            selectedPlatformIds: $selectedPlatformIds,
                            allowsMultipleSelection: false,
                            isDisabled: false
                        )
                    }
                } header: {
                    Text("Platform")
                } footer: {
                    Text("Select a platform to add \(gameTitle) to.")
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Platform")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .disabled(isAdding)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let platformId = selectedPlatformIds.first else { return }
                        Task {
                            isAdding = true
                            let success = await viewModel.addPlatformToGameFamily(
                                gameFamilyId: gameFamilyId,
                                platformId: platformId
                            )
                            isAdding = false
                            if success {
                                onDismiss()
                            }
                        }
                    }
                    .disabled(selectedPlatformIds.isEmpty || isAdding)
                }
            }
            .interactiveDismissDisabled(isAdding)
        }
        .presentationDetents([.medium, .large])
    }
}
