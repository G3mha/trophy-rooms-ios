import SwiftUI

/// The app's loading state.
///
/// Fills the available space on purpose: a bare `ProgressView` sizes to its
/// own content, which makes any canvas behind it shrink to a small patch and
/// leaves the rest of the screen black.
struct CabinetLoadingView: View {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(Cabinet.brass)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    CabinetLoadingView("Loading library...")
        .background(Cabinet.canvas)
}
