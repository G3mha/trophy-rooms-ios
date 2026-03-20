import SwiftUI

struct AdminGameFormSheet: View {
    @ObservedObject var viewModel: AdminGamesViewModel
    let game: AdminGame?
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var coverUrl: String = ""
    @State private var selectedPlatformId: String = ""
    @State private var isSaving = false

    var isEditing: Bool {
        game != nil
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !selectedPlatformId.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)

                    Picker("Platform", selection: $selectedPlatformId) {
                        Text("Select Platform").tag("")
                        ForEach(viewModel.platforms) { platform in
                            Text(platform.name).tag(platform.id)
                        }
                    }
                } header: {
                    Text("Game Details")
                }

                Section {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    TextField("Cover URL", text: $coverUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("Optional")
                }

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

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Game" : "New Game")
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
            if let game = game {
                title = game.title
                description = game.description ?? ""
                coverUrl = game.coverUrl ?? ""
                selectedPlatformId = game.platform?.id ?? ""
            } else if selectedPlatformId.isEmpty, let firstPlatform = viewModel.platforms.first {
                selectedPlatformId = firstPlatform.id
            }
        }
    }

    private func save() {
        isSaving = true

        Task {
            let success: Bool
            let desc = description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description.trimmingCharacters(in: .whitespaces)
            let cover = coverUrl.trimmingCharacters(in: .whitespaces).isEmpty ? nil : coverUrl.trimmingCharacters(in: .whitespaces)

            if let game = game {
                success = await viewModel.updateGame(
                    id: game.id,
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: desc,
                    coverUrl: cover,
                    platformId: selectedPlatformId
                )
            } else {
                success = await viewModel.createGame(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: desc,
                    coverUrl: cover,
                    platformId: selectedPlatformId
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
    AdminGameFormSheet(viewModel: AdminGamesViewModel(), game: nil)
}
