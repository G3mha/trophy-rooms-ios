import SwiftUI

struct GameCloneFormContent: View {
    let gameTitle: String
    let availablePlatforms: [AdminPlatform]
    @Binding var selectedPlatformIds: Set<String>
    @Binding var copyAchievementSets: Bool
    let errorMessage: String?

    var body: some View {
        Form {
            Section {
                Text(gameTitle)
                    .font(.headline)
            } header: {
                Text("Source Game")
            }

            Section {
                if availablePlatforms.isEmpty {
                    Text("No other platforms available")
                        .foregroundStyle(.secondary)
                } else {
                    PlatformSelectionField(
                        platforms: availablePlatforms,
                        selectedPlatformIds: $selectedPlatformIds,
                        allowsMultipleSelection: true,
                        isDisabled: false
                    )
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

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

struct GameCloneLoadingOverlay: View {
    var body: some View {
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

struct CloneResultsSheet: View {
    let results: [CloneResult]
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var succeeded: [CloneResult] {
        results.filter { $0.success }
    }

    private var failed: [CloneResult] {
        results.filter { !$0.success }
    }

    var body: some View {
        NavigationStack {
            List {
                if !succeeded.isEmpty {
                    Section {
                        ForEach(succeeded) { result in
                            HStack(spacing: 12) {
                                PlatformIcon(slug: result.platformSlug, size: 24)
                                Text(result.platformName)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.title3)
                            }
                        }
                    } header: {
                        Label("Succeeded", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                if !failed.isEmpty {
                    Section {
                        ForEach(failed) { result in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    PlatformIcon(slug: result.platformSlug, size: 24)
                                    Text(result.platformName)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                        .font(.title3)
                                }
                                if let error = result.error {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Label("Failed", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Clone Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
