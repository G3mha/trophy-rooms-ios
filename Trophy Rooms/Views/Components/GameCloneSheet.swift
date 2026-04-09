import SwiftUI

/// Sheet for cloning a game to other platforms
struct GameCloneSheet: View {
    let gameId: String
    let gameTitle: String
    let currentPlatformId: String?

    @ObservedObject var viewModel: AdminGamesViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlatformIds: Set<String> = []
    @State private var copyAchievementSets: Bool = true
    @State private var isCloning: Bool = false
    @State private var cloneResults: [CloneResult] = []
    @State private var showingResults: Bool = false

    private struct CloneResult: Identifiable {
        let id = UUID()
        let platformName: String
        let success: Bool
        let error: String?
    }

    var availablePlatforms: [AdminPlatform] {
        viewModel.platforms.filter { $0.id != currentPlatformId }
    }

    var isValid: Bool {
        !selectedPlatformIds.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(gameTitle)
                        .font(.headline)
                } header: {
                    Text("Source Game")
                }

                Section {
                    ForEach(availablePlatforms) { platform in
                        Button {
                            togglePlatform(platform.id)
                        } label: {
                            HStack {
                                PlatformIcon(slug: platform.slug, size: 20)
                                Text(platform.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedPlatformIds.contains(platform.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }

                    if availablePlatforms.isEmpty {
                        Text("No other platforms available")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Target Platforms")
                } footer: {
                    Text("Select one or more platforms to clone the game to")
                }

                Section {
                    Toggle("Copy Achievement Sets", isOn: $copyAchievementSets)
                } footer: {
                    Text("When enabled, all achievement sets from the source game will be copied to the cloned games")
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Clone Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Clone") {
                        cloneGame()
                    }
                    .disabled(!isValid || isCloning)
                }
            }
            .interactiveDismissDisabled(isCloning)
            .overlay {
                if isCloning {
                    ZStack {
                        Color.black.opacity(0.3)
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Cloning game...")
                                .font(.headline)
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .ignoresSafeArea()
                }
            }
            .alert("Clone Results", isPresented: $showingResults) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text(resultsMessage)
            }
        }
    }

    private func togglePlatform(_ platformId: String) {
        if selectedPlatformIds.contains(platformId) {
            selectedPlatformIds.remove(platformId)
        } else {
            selectedPlatformIds.insert(platformId)
        }
    }

    private func cloneGame() {
        isCloning = true
        cloneResults = []

        Task {
            var results: [CloneResult] = []

            for platformId in selectedPlatformIds {
                let platformName = viewModel.platforms.first { $0.id == platformId }?.name ?? "Unknown"
                let success = await viewModel.cloneGameToPlatform(
                    gameId: gameId,
                    targetPlatformId: platformId,
                    copyAchievementSets: copyAchievementSets
                )
                results.append(CloneResult(
                    platformName: platformName,
                    success: success,
                    error: success ? nil : viewModel.errorMessage
                ))
            }

            await MainActor.run {
                cloneResults = results
                isCloning = false

                // If all succeeded, just dismiss
                let allSucceeded = results.allSatisfy { $0.success }
                if allSucceeded {
                    NotificationCenter.default.post(name: .adminGameDidUpdate, object: nil)
                    dismiss()
                } else {
                    showingResults = true
                }
            }
        }
    }

    private var resultsMessage: String {
        let succeeded = cloneResults.filter { $0.success }
        let failed = cloneResults.filter { !$0.success }

        var message = ""
        if !succeeded.isEmpty {
            message += "Successfully cloned to: \(succeeded.map { $0.platformName }.joined(separator: ", "))"
        }
        if !failed.isEmpty {
            if !message.isEmpty { message += "\n\n" }
            let failedDetails = failed.map { result in
                if let error = result.error {
                    return "\(result.platformName): \(error)"
                }
                return result.platformName
            }
            message += "Failed:\n\(failedDetails.joined(separator: "\n"))"
        }
        return message
    }
}

#Preview {
    GameCloneSheet(
        gameId: "1",
        gameTitle: "Test Game",
        currentPlatformId: "1",
        viewModel: AdminGamesViewModel()
    )
}
