import SwiftUI

/// Signed-out placeholder for tabs that need an account.
///
/// The trophy shelf IS the emblem here, standing in for the grey SF Symbol a
/// zero state would normally use - one focal image rather than a generic glyph
/// up top plus a decorative band at the bottom.
struct SignInPrompt: View {
    let message: String
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            TrophyShelfView()

            Text(message)
                .font(.headline)

            Button("Sign In", action: onSignIn)
                .buttonStyle(.borderedProminent)

            Spacer()
        }
    }
}
