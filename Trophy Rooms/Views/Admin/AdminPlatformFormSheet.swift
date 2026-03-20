import SwiftUI

struct AdminPlatformFormSheet: View {
    @ObservedObject var viewModel: AdminPlatformsViewModel
    let platform: AdminPlatform?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var slug: String = ""
    @State private var isSaving = false

    var isEditing: Bool {
        platform != nil
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
                    Text("Platform Details")
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Platform" : "New Platform")
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
            if let platform = platform {
                name = platform.name
                slug = platform.slug
            }
        }
    }

    private func save() {
        isSaving = true

        Task {
            let success: Bool
            if let platform = platform {
                success = await viewModel.updatePlatform(
                    id: platform.id,
                    name: name.trimmingCharacters(in: .whitespaces),
                    slug: slug.trimmingCharacters(in: .whitespaces)
                )
            } else {
                success = await viewModel.createPlatform(
                    name: name.trimmingCharacters(in: .whitespaces),
                    slug: slug.trimmingCharacters(in: .whitespaces)
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
    AdminPlatformFormSheet(viewModel: AdminPlatformsViewModel(), platform: nil)
}
