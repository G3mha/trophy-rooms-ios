import SwiftUI

struct AdminGameVersionFormSheet: View {
    @ObservedObject var viewModel: AdminGameVersionsViewModel
    let gameId: String
    let version: GameVersion?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var slug: String = ""
    @State private var description: String = ""
    @State private var coverUrl: String = ""
    @State private var selectedDlcIds: [String] = []
    @State private var isDefault: Bool = false
    @State private var isSaving = false
    @State private var availableDlcs: [DLC] = []
    @State private var isLoadingDlcs = false

    var isEditing: Bool {
        version != nil
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !slug.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Slug", text: $slug)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Version Details")
                } footer: {
                    Text("Examples: Standard, Deluxe Edition, Game of the Year Edition")
                }

                Section {
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Description")
                }

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

                if !isEditing {
                    Section {
                        Toggle("Set as Default", isOn: $isDefault)
                    } header: {
                        Text("Default Version")
                    } footer: {
                        Text("The default version is selected automatically when users add this game to their library")
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Version" : "New Version")
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
            if let version = version {
                name = version.name
                slug = version.slug ?? ""
                description = version.description ?? ""
                coverUrl = version.coverUrl ?? ""
                selectedDlcIds = version.dlcs?.map { $0.id } ?? []
                isDefault = version.isDefault
            }
        }
        .task {
            await fetchDlcs()
        }
    }

    private func fetchDlcs() async {
        isLoadingDlcs = true
        let query = """
        query GetDLCs($gameId: ID!) {
            dlcs(gameId: $gameId) {
                id
                name
                slug
                type
            }
        }
        """

        do {
            let response: DLCsResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["gameId": gameId]
            )
            DispatchQueue.main.async {
                self.availableDlcs = response.dlcs
                self.isLoadingDlcs = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isLoadingDlcs = false
            }
        }
    }

    private func save() {
        isSaving = true

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedSlug = slug.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = description.trimmingCharacters(in: .whitespaces)
        let trimmedCoverUrl = coverUrl.trimmingCharacters(in: .whitespaces)

        let dlcIds: [String]? = selectedDlcIds.isEmpty ? nil : selectedDlcIds

        Task {
            let success: Bool
            if let version = version {
                success = await viewModel.updateVersion(
                    id: version.id,
                    gameId: gameId,
                    name: trimmedName,
                    slug: trimmedSlug,
                    description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                    coverUrl: trimmedCoverUrl.isEmpty ? nil : trimmedCoverUrl,
                    dlcIds: dlcIds
                )
            } else {
                success = await viewModel.createVersion(
                    gameId: gameId,
                    name: trimmedName,
                    slug: trimmedSlug,
                    description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                    coverUrl: trimmedCoverUrl.isEmpty ? nil : trimmedCoverUrl,
                    dlcIds: dlcIds,
                    isDefault: isDefault
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
    AdminGameVersionFormSheet(
        viewModel: AdminGameVersionsViewModel(),
        gameId: "test-game-id",
        version: nil
    )
}
