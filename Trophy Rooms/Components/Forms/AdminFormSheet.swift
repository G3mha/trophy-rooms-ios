import SwiftUI

/// A reusable container for admin form sheets with consistent structure
struct AdminFormSheet<Content: View>: View {
    let title: String
    let isEditing: Bool
    let isSaving: Bool
    let isValid: Bool
    let errorMessage: String?
    let onCancel: () -> Void
    let onSave: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationStack {
            Form {
                content()

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create", action: onSave)
                        .disabled(!isValid || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}

// MARK: - Convenience Initializer

extension AdminFormSheet {
    init(
        entityName: String,
        isEditing: Bool,
        isSaving: Bool,
        isValid: Bool,
        errorMessage: String?,
        onCancel: @escaping () -> Void,
        onSave: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = isEditing ? "Edit \(entityName)" : "New \(entityName)"
        self.isEditing = isEditing
        self.isSaving = isSaving
        self.isValid = isValid
        self.errorMessage = errorMessage
        self.onCancel = onCancel
        self.onSave = onSave
        self.content = content
    }
}

// MARK: - Form Section Helpers

/// Standard form section with header
struct FormSection<Content: View>: View {
    let header: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        Section {
            content()
        } header: {
            Text(header)
        }
    }
}

#Preview("New Entity") {
    AdminFormSheet(
        entityName: "Platform",
        isEditing: false,
        isSaving: false,
        isValid: true,
        errorMessage: nil,
        onCancel: {},
        onSave: {}
    ) {
        Section("Details") {
            TextField("Name", text: .constant(""))
            TextField("Slug", text: .constant(""))
        }
    }
}

#Preview("Edit Entity") {
    AdminFormSheet(
        entityName: "Platform",
        isEditing: true,
        isSaving: false,
        isValid: true,
        errorMessage: nil,
        onCancel: {},
        onSave: {}
    ) {
        Section("Details") {
            TextField("Name", text: .constant("PlayStation 5"))
            TextField("Slug", text: .constant("ps5"))
        }
    }
}

#Preview("With Error") {
    AdminFormSheet(
        entityName: "Platform",
        isEditing: false,
        isSaving: false,
        isValid: true,
        errorMessage: "Failed to create platform: Network error",
        onCancel: {},
        onSave: {}
    ) {
        Section("Details") {
            TextField("Name", text: .constant(""))
            TextField("Slug", text: .constant(""))
        }
    }
}
