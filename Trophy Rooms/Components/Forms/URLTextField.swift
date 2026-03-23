import SwiftUI

/// A text field configured for URL input
struct URLTextField: View {
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
            .keyboardType(.URL)
    }
}

#Preview {
    Form {
        URLTextField("Cover URL", text: .constant("https://example.com/image.jpg"))
        URLTextField("Website", text: .constant(""))
    }
}
