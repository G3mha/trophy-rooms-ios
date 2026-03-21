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
    @State private var includedDlcText: String = ""
    @State private var isDefault: Bool = false
    @State private var isSaving = false

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
                    TextField("DLC names (comma-separated)", text: $includedDlcText, axis: .vertical)
                        .lineLimit(2...4)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Included DLC")
                } footer: {
                    Text("Enter DLC names separated by commas. Example: Season Pass, Bonus Skins, Extra Maps")
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
                includedDlcText = version.includedDlc?.joined(separator: ", ") ?? ""
                isDefault = version.isDefault
            }
        }
    }

    private func save() {
        isSaving = true

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedSlug = slug.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = description.trimmingCharacters(in: .whitespaces)
        let trimmedCoverUrl = coverUrl.trimmingCharacters(in: .whitespaces)

        let dlcArray: [String]? = {
            let trimmed = includedDlcText.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                return nil
            }
            return trimmed
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }()

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
                    includedDlc: dlcArray
                )
            } else {
                success = await viewModel.createVersion(
                    gameId: gameId,
                    name: trimmedName,
                    slug: trimmedSlug,
                    description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                    coverUrl: trimmedCoverUrl.isEmpty ? nil : trimmedCoverUrl,
                    includedDlc: dlcArray,
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
