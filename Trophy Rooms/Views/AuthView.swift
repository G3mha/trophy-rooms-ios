import SwiftUI
import ClerkKit
import AuthenticationServices

enum AuthMode {
    case signIn
    case signUp
}

enum AuthStep {
    case form
    case verification
}

struct AuthView: View {
    @Environment(Clerk.self) private var clerk
    @Environment(\.dismiss) private var dismiss

    @State private var mode: AuthMode = .signIn
    @State private var step: AuthStep = .form
    @State private var email = ""
    @State private var password = ""
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false
    @State private var currentSignUp: SignUp?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("🏆")
                            .font(.system(size: 56))

                        Text(headerTitle)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(headerSubtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 16)

                    // Card
                    VStack(spacing: 20) {
                        if step == .verification {
                            verificationView
                        } else {
                            formView
                        }
                    }
                    .padding(24)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerTitle: String {
        switch (mode, step) {
        case (.signIn, _): return "Welcome Back"
        case (.signUp, .form): return "Create Account"
        case (.signUp, .verification): return "Verify Your Email"
        }
    }

    private var headerSubtitle: String {
        switch (mode, step) {
        case (.signIn, _): return "Sign in to continue to Trophy Rooms"
        case (.signUp, .form): return "Join Trophy Rooms and start tracking"
        case (.signUp, .verification): return "We sent a verification code to your email"
        }
    }

    // MARK: - Form View

    private var formView: some View {
        VStack(spacing: 20) {
            // Google Sign In
            GoogleSignInButton(isLoading: isLoading) {
                Task {
                    await handleGoogleSignIn()
                }
            }

            // Divider
            HStack(spacing: 16) {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1)
                Text("or")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 1)
            }

            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextField("Enter your email", text: $email)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }

            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack {
                    if showPassword {
                        TextField("Enter your password", text: $password)
                    } else {
                        SecureField("Enter your password", text: $password)
                    }

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 1)
                )
                .textContentType(mode == .signUp ? .newPassword : .password)

                if mode == .signUp {
                    Text("Must be at least 8 characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Submit button
            Button {
                Task {
                    if mode == .signIn {
                        await handleEmailSignIn()
                    } else {
                        await handleEmailSignUp()
                    }
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(mode == .signIn ? "Sign In" : "Create Account")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .fontWeight(.semibold)
            }
            .buttonStyle(.glassProminent)
            .tint(.accentColor)
            .disabled(isLoading || email.isEmpty || password.isEmpty)

            // Switch mode
            HStack {
                Text(mode == .signIn ? "Don't have an account?" : "Already have an account?")
                    .foregroundColor(.secondary)

                Button(mode == .signIn ? "Sign up" : "Sign in") {
                    withAnimation {
                        mode = mode == .signIn ? .signUp : .signIn
                        errorMessage = nil
                    }
                }
                .foregroundColor(Color.accentColor)
                .fontWeight(.medium)
            }
            .font(.subheadline)
        }
    }

    // MARK: - Verification View

    private var verificationView: some View {
        VStack(spacing: 24) {
            // Code input
            VStack(alignment: .leading, spacing: 8) {
                Text("Verification Code")
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextField("Enter 6-digit code", text: $verificationCode)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separator), lineWidth: 1)
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.title2.monospacedDigit())
                    .onChange(of: verificationCode) {
                        // Auto-submit when 6 digits entered
                        if verificationCode.count == 6 {
                            Task {
                                await handleVerification()
                            }
                        }
                    }
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Verify button
            Button {
                Task {
                    await handleVerification()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Verify Email")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .fontWeight(.semibold)
            }
            .buttonStyle(.glassProminent)
            .tint(.accentColor)
            .disabled(isLoading || verificationCode.count < 6)

            // Resend code
            HStack {
                Text("Didn't receive a code?")
                    .foregroundColor(.secondary)

                Button("Resend") {
                    Task {
                        await handleResendCode()
                    }
                }
                .foregroundColor(Color.accentColor)
                .fontWeight(.medium)
            }
            .font(.subheadline)

            // Back button
            Button {
                withAnimation {
                    step = .form
                    verificationCode = ""
                    errorMessage = nil
                }
            } label: {
                Text("Back to sign up")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func handleEmailSignIn() async {
        guard !email.isEmpty, !password.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let signIn = try await clerk.auth.signInWithPassword(
                identifier: email,
                password: password
            )

            if signIn.status == .complete {
                dismiss()
            } else {
                errorMessage = "Sign in incomplete. Please try again."
            }
        } catch {
            errorMessage = parseClerkError(error)
        }

        isLoading = false
    }

    private func handleEmailSignUp() async {
        guard !email.isEmpty, !password.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            var signUp = try await clerk.auth.signUp(
                emailAddress: email,
                password: password
            )

            signUp = try await signUp.sendEmailCode()
            currentSignUp = signUp

            withAnimation {
                step = .verification
            }
        } catch {
            errorMessage = parseClerkError(error)
        }

        isLoading = false
    }

    private func handleVerification() async {
        guard verificationCode.count == 6, var signUp = currentSignUp else { return }

        isLoading = true
        errorMessage = nil

        do {
            signUp = try await signUp.verifyEmailCode(verificationCode)

            if signUp.status == .complete {
                dismiss()
            } else {
                errorMessage = "Verification incomplete. Please try again."
            }
        } catch {
            errorMessage = parseClerkError(error)
        }

        isLoading = false
    }

    private func handleResendCode() async {
        guard var signUp = currentSignUp else { return }
        errorMessage = nil

        do {
            signUp = try await signUp.sendEmailCode()
            currentSignUp = signUp
        } catch {
            errorMessage = parseClerkError(error)
        }
    }

    private func handleGoogleSignIn() async {
        isLoading = true
        errorMessage = nil

        do {
            if mode == .signIn {
                _ = try await clerk.auth.signInWithOAuth(provider: .google)
            } else {
                _ = try await clerk.auth.signUpWithOAuth(provider: .google)
            }
            dismiss()
        } catch {
            errorMessage = parseClerkError(error)
        }

        isLoading = false
    }

    private func parseClerkError(_ error: Error) -> String {
        if let clerkError = error as? ClerkAPIError {
            return clerkError.localizedDescription
        }
        return error.localizedDescription
    }
}

// MARK: - Google Sign In Button
// Follows Google's branding guidelines (developers.google.com/identity/branding-guidelines):
// light theme #FFFFFF fill / #747775 stroke / #1F1F1F text, dark theme #131314 fill /
// #8E918F stroke / #E3E3E3 text, 40pt height, 20pt logo, 16pt side padding, 12pt gap.

struct GoogleSignInButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let isLoading: Bool
    let action: () -> Void

    private var fillColor: Color {
        colorScheme == .dark
            ? Color(red: 19 / 255, green: 19 / 255, blue: 20 / 255)
            : .white
    }

    private var strokeColor: Color {
        colorScheme == .dark
            ? Color(red: 142 / 255, green: 145 / 255, blue: 143 / 255)
            : Color(red: 116 / 255, green: 119 / 255, blue: 117 / 255)
    }

    private var textColor: Color {
        colorScheme == .dark
            ? Color(red: 227 / 255, green: 227 / 255, blue: 227 / 255)
            : Color(red: 31 / 255, green: 31 / 255, blue: 31 / 255)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .frame(width: 20, height: 20)
                } else {
                    GoogleLogo()
                        .frame(width: 20, height: 20)
                }

                Text("Continue with Google")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(fillColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(strokeColor, lineWidth: 1)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - Google Logo
// Official multi-color "G", traced from Google's standard 24x24 logo asset.
// The guidelines prohibit recoloring or redrawing it, so the paths must not be altered.

struct GoogleLogo: View {
    var body: some View {
        Canvas { context, size in
            let s = size.width / 24

            var blue = Path()
            blue.move(to: CGPoint(x: 22.56 * s, y: 12.25 * s))
            blue.addCurve(
                to: CGPoint(x: 22.36 * s, y: 10 * s),
                control1: CGPoint(x: 22.56 * s, y: 11.47 * s),
                control2: CGPoint(x: 22.49 * s, y: 10.72 * s)
            )
            blue.addLine(to: CGPoint(x: 12 * s, y: 10 * s))
            blue.addLine(to: CGPoint(x: 12 * s, y: 14.26 * s))
            blue.addLine(to: CGPoint(x: 17.92 * s, y: 14.26 * s))
            blue.addCurve(
                to: CGPoint(x: 15.71 * s, y: 17.57 * s),
                control1: CGPoint(x: 17.66 * s, y: 15.63 * s),
                control2: CGPoint(x: 16.88 * s, y: 16.79 * s)
            )
            blue.addLine(to: CGPoint(x: 15.71 * s, y: 20.34 * s))
            blue.addLine(to: CGPoint(x: 19.28 * s, y: 20.34 * s))
            blue.addCurve(
                to: CGPoint(x: 22.56 * s, y: 12.25 * s),
                control1: CGPoint(x: 21.36 * s, y: 18.42 * s),
                control2: CGPoint(x: 22.56 * s, y: 15.6 * s)
            )
            blue.closeSubpath()
            context.fill(blue, with: .color(Color(red: 66 / 255, green: 133 / 255, blue: 244 / 255)))

            var green = Path()
            green.move(to: CGPoint(x: 12 * s, y: 23 * s))
            green.addCurve(
                to: CGPoint(x: 19.28 * s, y: 20.34 * s),
                control1: CGPoint(x: 14.97 * s, y: 23 * s),
                control2: CGPoint(x: 17.46 * s, y: 22.02 * s)
            )
            green.addLine(to: CGPoint(x: 15.71 * s, y: 17.57 * s))
            green.addCurve(
                to: CGPoint(x: 12 * s, y: 18.63 * s),
                control1: CGPoint(x: 14.73 * s, y: 18.23 * s),
                control2: CGPoint(x: 13.48 * s, y: 18.63 * s)
            )
            green.addCurve(
                to: CGPoint(x: 5.84 * s, y: 14.1 * s),
                control1: CGPoint(x: 9.14 * s, y: 18.63 * s),
                control2: CGPoint(x: 6.71 * s, y: 16.7 * s)
            )
            green.addLine(to: CGPoint(x: 2.18 * s, y: 14.1 * s))
            green.addLine(to: CGPoint(x: 2.18 * s, y: 16.94 * s))
            green.addCurve(
                to: CGPoint(x: 12 * s, y: 23 * s),
                control1: CGPoint(x: 3.99 * s, y: 20.53 * s),
                control2: CGPoint(x: 7.7 * s, y: 23 * s)
            )
            green.closeSubpath()
            context.fill(green, with: .color(Color(red: 52 / 255, green: 168 / 255, blue: 83 / 255)))

            var yellow = Path()
            yellow.move(to: CGPoint(x: 5.84 * s, y: 14.09 * s))
            yellow.addCurve(
                to: CGPoint(x: 5.49 * s, y: 12 * s),
                control1: CGPoint(x: 5.62 * s, y: 13.43 * s),
                control2: CGPoint(x: 5.49 * s, y: 12.73 * s)
            )
            yellow.addCurve(
                to: CGPoint(x: 5.84 * s, y: 9.91 * s),
                control1: CGPoint(x: 5.49 * s, y: 11.27 * s),
                control2: CGPoint(x: 5.62 * s, y: 10.57 * s)
            )
            yellow.addLine(to: CGPoint(x: 5.84 * s, y: 7.07 * s))
            yellow.addLine(to: CGPoint(x: 2.18 * s, y: 7.07 * s))
            yellow.addCurve(
                to: CGPoint(x: 1 * s, y: 12 * s),
                control1: CGPoint(x: 1.43 * s, y: 8.55 * s),
                control2: CGPoint(x: 1 * s, y: 10.22 * s)
            )
            yellow.addCurve(
                to: CGPoint(x: 2.18 * s, y: 16.93 * s),
                control1: CGPoint(x: 1 * s, y: 13.78 * s),
                control2: CGPoint(x: 1.43 * s, y: 15.45 * s)
            )
            yellow.addLine(to: CGPoint(x: 5.03 * s, y: 14.71 * s))
            yellow.addLine(to: CGPoint(x: 5.84 * s, y: 14.09 * s))
            yellow.closeSubpath()
            context.fill(yellow, with: .color(Color(red: 251 / 255, green: 188 / 255, blue: 5 / 255)))

            var red = Path()
            red.move(to: CGPoint(x: 12 * s, y: 5.38 * s))
            red.addCurve(
                to: CGPoint(x: 16.21 * s, y: 7.02 * s),
                control1: CGPoint(x: 13.62 * s, y: 5.38 * s),
                control2: CGPoint(x: 15.06 * s, y: 5.94 * s)
            )
            red.addLine(to: CGPoint(x: 19.36 * s, y: 3.87 * s))
            red.addCurve(
                to: CGPoint(x: 12 * s, y: 1 * s),
                control1: CGPoint(x: 17.45 * s, y: 2.09 * s),
                control2: CGPoint(x: 14.97 * s, y: 1 * s)
            )
            red.addCurve(
                to: CGPoint(x: 2.18 * s, y: 7.07 * s),
                control1: CGPoint(x: 7.7 * s, y: 1 * s),
                control2: CGPoint(x: 3.99 * s, y: 3.47 * s)
            )
            red.addLine(to: CGPoint(x: 5.84 * s, y: 9.91 * s))
            red.addCurve(
                to: CGPoint(x: 12 * s, y: 5.38 * s),
                control1: CGPoint(x: 6.71 * s, y: 7.31 * s),
                control2: CGPoint(x: 9.14 * s, y: 5.38 * s)
            )
            red.closeSubpath()
            context.fill(red, with: .color(Color(red: 234 / 255, green: 67 / 255, blue: 53 / 255)))
        }
    }
}

#Preview {
    AuthView()
}
