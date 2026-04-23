import SwiftUI

struct AdminGameVersionDetailsSection: View {
    @Binding var name: String
    @Binding var slug: String
    let isEditing: Bool

    var body: some View {
        Section {
            TextField("Name", text: $name)
                .textInputAutocapitalization(.words)

            AutoSlugTextField("Slug", slug: $slug, from: name, isEditing: isEditing)
        } header: {
            Text("Version Details")
        } footer: {
            Text("Examples: Standard, Deluxe Edition, Game of the Year Edition")
        }
    }
}

struct AdminGameVersionPlatformsSection: View {
    let availableGames: [FamilyGame]
    @Binding var selectedGameIds: Set<String>
    let isLoadingGames: Bool

    var body: some View {
        Section {
            if isLoadingGames {
                ProgressView("Loading platforms...")
            } else if availableGames.isEmpty {
                Text("No platform versions available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(availableGames, id: \.id) { game in
                    HStack {
                        if let platform = game.platform {
                            PlatformIcon(slug: platform.slug ?? "", size: 20)
                        }
                        VStack(alignment: .leading) {
                            Text(game.platform?.name ?? "Unknown Platform")
                            if let platformSlug = game.platform?.slug {
                                Text(platformSlug)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if selectedGameIds.contains(game.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedGameIds.contains(game.id) {
                            selectedGameIds.remove(game.id)
                        } else {
                            selectedGameIds.insert(game.id)
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("Available On")
                Spacer()
                if !availableGames.isEmpty {
                    Text("\(selectedGameIds.count) of \(availableGames.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } footer: {
            if !availableGames.isEmpty {
                HStack(spacing: 16) {
                    Button("Select All") {
                        selectedGameIds = Set(availableGames.map { $0.id })
                    }
                    .disabled(selectedGameIds.count == availableGames.count)

                    Button("Clear All") {
                        selectedGameIds.removeAll()
                    }
                    .disabled(selectedGameIds.isEmpty)
                }
                .font(.caption)
            }
        }
    }
}

struct AdminGameVersionDescriptionSection: View {
    @Binding var description: String

    var body: some View {
        Section {
            TextField("Description (optional)", text: $description, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Description")
        }
    }
}

struct AdminGameVersionCoverSection: View {
    @Binding var coverUrl: String

    var body: some View {
        Section {
            TextField("Cover URL (optional)", text: $coverUrl)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
        } header: {
            Text("Cover Image")
        } footer: {
            Text("Leave empty to use the game's cover image")
        }
    }
}

struct AdminGameVersionCoverPreviewSection: View {
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

struct AdminGameVersionDLCSection: View {
    let availableDlcs: [DLC]
    @Binding var selectedDlcIds: [String]
    let isLoadingDlcs: Bool

    var body: some View {
        Section {
            if isLoadingDlcs {
                ProgressView("Loading DLCs...")
            } else if availableDlcs.isEmpty {
                Text("No DLCs available for this game")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(availableDlcs, id: \.id) { dlc in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(dlc.name)
                            Text(dlc.type.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedDlcIds.contains(dlc.id) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedDlcIds.contains(dlc.id) {
                            selectedDlcIds.removeAll { $0 == dlc.id }
                        } else {
                            selectedDlcIds.append(dlc.id)
                        }
                    }
                }
            }
        } header: {
            Text("Included DLC")
        } footer: {
            if !availableDlcs.isEmpty {
                Text("Tap to select DLCs included in this version")
            }
        }
    }
}

struct AdminGameVersionDefaultSection: View {
    let isEditing: Bool
    @Binding var isDefault: Bool

    var body: some View {
        if !isEditing {
            Section {
                Toggle("Set as Default", isOn: $isDefault)
            } header: {
                Text("Default Version")
            } footer: {
                Text("The default version is selected automatically when users add this game to their library")
            }
        }
    }
}

struct AdminGameVersionDistributionSection: View {
    @Binding var digitalOnly: Bool

    var body: some View {
        Section {
            Toggle("Digital Only", isOn: $digitalOnly)
        } header: {
            Text("Distribution")
        } footer: {
            Text("If enabled, users can only add this version as a digital copy (no physical option)")
        }
    }
}

struct AdminGameVersionErrorSection: View {
    let error: String

    var body: some View {
        Section {
            Text(error)
                .foregroundStyle(.red)
        }
    }
}
