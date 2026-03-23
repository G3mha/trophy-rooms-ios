import SwiftUI

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
