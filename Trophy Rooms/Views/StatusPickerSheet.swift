import SwiftUI

struct StatusPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var platformsViewModel = PlatformsViewModel.shared
    @State private var selectedPlatformId: String?
    @State private var selectedVersionId: String?

    let currentStatus: GameStatus?
    let currentPlatformId: String?
    let currentVersionId: String?
    let versions: [GameVersion]
    let onSelect: (GameStatus, String?, String?) -> Void
    let onClear: () -> Void

    var body: some View {
        NavigationStack {
            List {
                // Platform picker
                Section("Platform (Optional)") {
                    Picker("Platform", selection: $selectedPlatformId) {
                        Text("No Platform").tag(nil as String?)
                        ForEach(platformsViewModel.platforms) { platform in
                            Text(platform.name).tag(platform.id as String?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Version picker (only show if multiple versions exist)
                if versions.count > 1 {
                    Section("Version (Optional)") {
                        Picker("Version", selection: $selectedVersionId) {
                            Text("No Version").tag(nil as String?)
                            ForEach(versions, id: \.id) { version in
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
                    ForEach(GameStatus.activeStatuses, id: \.self) { status in
                        Button {
                            onSelect(status, selectedPlatformId, selectedVersionId)
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
                selectedPlatformId = currentPlatformId
                selectedVersionId = currentVersionId
            }
        }
        .presentationDetents([.medium])
    }

    func statusColor(for status: GameStatus) -> Color {
        switch status {
        case .WISHLIST: return .pink
        case .BACKLOG: return .blue
        case .PLAYING: return .green
        case .PAUSED: return .orange
        case .COMPLETED: return .purple
        case .DROPPED: return .gray
        }
    }
}
