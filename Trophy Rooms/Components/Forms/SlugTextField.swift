import SwiftUI

// MARK: - Slug Generation

extension String {
    /// Generates a URL-friendly slug from a string
    /// Matches the backend's generateSlug function
    func toSlug() -> String {
        self.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            .prefix(100)
            .description
    }
}

/// A text field configured for slug input (lowercase, no autocorrect)
struct SlugTextField: View {
    let label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        self._text = text
    }

    var body: some View {
        TextField(label, text: $text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }
}

/// A text field that auto-generates slug from a source text (like title/name)
struct AutoSlugTextField: View {
    let label: String
    @Binding var slug: String
    let sourceText: String
    let isEditing: Bool

    @State private var hasManuallyEdited = false

    init(_ label: String, slug: Binding<String>, from sourceText: String, isEditing: Bool = false) {
        self.label = label
        self._slug = slug
        self.sourceText = sourceText
        self.isEditing = isEditing
    }

    var body: some View {
        TextField(label, text: $slug)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onChange(of: sourceText) { _, newValue in
                // Only auto-generate if not manually edited and not in edit mode
                if !hasManuallyEdited && !isEditing {
                    slug = newValue.toSlug()
                }
            }
            .onChange(of: slug) { oldValue, newValue in
                // Detect manual editing (when slug doesn't match auto-generated)
                let expectedSlug = sourceText.toSlug()
                if newValue != expectedSlug && newValue != oldValue {
                    hasManuallyEdited = true
                }
            }
    }
}

/// A text field configured for standard text input (auto-capitalize words)
struct NameTextField: View {
    let label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        self._text = text
    }

    var body: some View {
        TextField(label, text: $text)
            .textInputAutocapitalization(.words)
    }
}

/// A text field for multiline descriptions
struct DescriptionTextField: View {
    let label: String
    @Binding var text: String
    let lineRange: ClosedRange<Int>

    init(_ label: String, text: Binding<String>, lines: ClosedRange<Int> = 3...6) {
        self.label = label
        self._text = text
        self.lineRange = lines
    }

    var body: some View {
        TextField(label, text: $text, axis: .vertical)
            .lineLimit(lineRange)
    }
}

/// A text field for price input
struct PriceTextField: View {
    let label: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>) {
        self.label = label
        self._text = text
    }

    var body: some View {
        TextField(label, text: $text)
            .keyboardType(.decimalPad)
    }
}

#Preview {
    Form {
        Section("Form Fields") {
            NameTextField("Name", text: .constant(""))
            SlugTextField("Slug", text: .constant(""))
            URLTextField("Cover URL", text: .constant(""))
            DescriptionTextField("Description", text: .constant(""))
            PriceTextField("Price", text: .constant(""))
        }
    }
}
