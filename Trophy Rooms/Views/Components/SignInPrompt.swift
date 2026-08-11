import SwiftUI

/// Signed-out placeholder for tabs that need an account. The icon sits in a
/// fixed frame so different SF Symbol glyph proportions can't shift the
/// spacing between icon and text from one tab to another. The trophy shelf
/// beneath carries the cabinet identity.
struct SignInPrompt: View {
    let icon: String
    let message: String
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundColor(.secondary)
                .frame(width: 56, height: 56)

            Text(message)
                .font(.headline)

            Button("Sign In", action: onSignIn)
                .buttonStyle(.borderedProminent)

            Spacer()

            TrophyShelfView()
        }
    }
}
