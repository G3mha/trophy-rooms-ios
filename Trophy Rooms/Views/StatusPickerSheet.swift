import SwiftUI

struct StatusPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var platformsViewModel = PlatformsViewModel.shared
    @State private var selectedPlatformIds: Set<String> = []
    @State private var selectedVersionId: String?

    let currentStatus: GameStatus?
    let currentPlatformId: String?
    let currentVersionId: String?
    let versions: [GameVersion]
    let onSelect: (GameStatus, String?, String?) -> Void
    let onClear: () -> Void

    /// Filter versions based on selected platform
    var filteredVersions: [GameVersion] {
        guard let platformId = selectedPlatformIds.first else {
            return versions
        }
        return versions.filter { version in
            guard let games = version.games else { return true }
            return games.contains { $0.platform?.id == platformId }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Platform picker
                Section {
                    PlatformSelectionField(
                        platforms: platformsViewModel.platforms,
                        selectedPlatformIds: $selectedPlatformIds,
                        allowsMultipleSelection: false,
                        isDisabled: false
                    )
                } header: {
                    Text("Platform (Optional)")
                }

                // Version picker (only show if multiple versions available for platform)
                if filteredVersions.count > 1 {
                    Section("Version (Optional)") {
                        Picker("Version", selection: $selectedVersionId) {
                            Text("No Version").tag(nil as String?)
                            ForEach(filteredVersions, id: \.id) { version in
                                HStack {
                                    Text(version.name)
                                    if version.isDefault {
                                        Text("(Default)")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tag(version.id as String?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                // Status options
                Section("Status") {
                    ForEach(GameStatus.allCases, id: \.self) { status in
                        Button {
                            onSelect(status, selectedPlatformIds.first, selectedVersionId)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: status.iconName)
                                    .foregroundColor(statusColor(for: status))
                                    .frame(width: 24)
                                Text(status.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if currentStatus == status {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }

                if currentStatus != nil {
                    Section {
                        Button(role: .destructive) {
                            onClear()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                    .frame(width: 24)
                                Text("Remove from Library")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Set Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await platformsViewModel.fetchPlatforms()
                if let platformId = currentPlatformId {
                    selectedPlatformIds = [platformId]
                }
                selectedVersionId = currentVersionId
            }
            .onChange(of: selectedPlatformIds) { _, _ in
                // Clear version if it's no longer available for the selected platform
                if let versionId = selectedVersionId,
                   !filteredVersions.contains(where: { $0.id == versionId }) {
                    selectedVersionId = nil
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    func statusColor(for status: GameStatus) -> Color {
        switch status {
        case .BACKLOG: return .blue
        case .PLAYING: return .green
        case .PAUSED: return .orange
        case .COMPLETED: return .purple
        case .DROPPED: return .gray
        }
    }
}
