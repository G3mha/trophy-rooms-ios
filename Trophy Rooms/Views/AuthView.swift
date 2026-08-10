import SwiftUI
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
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var mode: AuthMode = .signIn
    @State private var step: AuthStep = .form
    @State private var email = ""
    @State private var password = ""
    @State private var verificationCode = ""
    private enum LoadingAction {
        case apple
        case google
        case credentials
    }

    @State private var loadingAction: LoadingAction?

    /// Any auth flow in flight (used to disable all controls)
    private var isLoading: Bool { loadingAction != nil }
    @State private var errorMessage: String?
    @State private var showPassword = false

    private enum Field: Hashable {
        case email
        case password
        case code
    }

    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 14) {
                        Image("AuthHeroTrophies")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 300)
                            .accessibilityLabel("Platform trophies")

                        Text(headerTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .contentTransition(.opacity)

                        Text(headerSubtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 8)

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
        .presentationDragIndicator(.visible)
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
            VStack(spacing: 12) {
                // Apple Sign In (required alongside third-party login, guideline 4.8)
                AppleSignInButton(isLoading: loadingAction == .apple) {
                    Task {
                        await handleAppleSignIn()
                    }
                }
                .disabled(isLoading)

                // Google Sign In
                GoogleSignInButton(isLoading: loadingAction == .google) {
                    Task {
                        await handleGoogleSignIn()
                    }
                }
                .disabled(isLoading)
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

            // Credential fields, grouped like a system login form
            VStack(alignment: .leading, spacing: 6) {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)

                        TextField("Email", text: $email)
                            .textFieldStyle(.plain)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    .padding(14)

                    Divider()
                        .padding(.leading, 44)

                    HStack(spacing: 10) {
                        Image(systemName: "lock")
                            .foregroundStyle(.secondary)
                            .frame(width: 20)

                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .textFieldStyle(.plain)
                        .textContentType(mode == .signUp ? .newPassword : .password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit {
                            submitCredentials()
                        }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(14)
                }
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            focusedField == .email || focusedField == .password
                                ? Color.accentColor.opacity(0.6)
                                : Color(.separator),
                            lineWidth: 1
                        )
                )
                .animation(.easeOut(duration: 0.15), value: focusedField)

                if mode == .signUp {
                    Text("Must be at least 8 characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }

            // Error message
            if let error = errorMessage {
                AuthErrorBanner(message: error)
            }

            // Submit button
            Button {
                submitCredentials()
            } label: {
                HStack {
                    if loadingAction == .credentials {
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
            // Six-digit code boxes over an invisible field, so system
            // one-time-code autofill and the number pad both work
            ZStack {
                TextField("", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($focusedField, equals: .code)
                    .opacity(0.02)
                    .onChange(of: verificationCode) {
                        verificationCode = String(verificationCode.filter(\.isNumber).prefix(6))
                        if verificationCode.count == 6 {
                            Task {
                                await handleVerification()
                            }
                        }
                    }

                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { index in
                        let digits = Array(verificationCode)
                        let isCursor = index == verificationCode.count && focusedField == .code

                        Text(index < digits.count ? String(digits[index]) : " ")
                            .font(.title2.weight(.semibold).monospacedDigit())
                            .frame(width: 42, height: 52)
                            .background(
                                Color(.systemBackground),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(
                                        isCursor ? Color.accentColor : Color(.separator),
                                        lineWidth: isCursor ? 2 : 1
                                    )
                            )
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = .code
                }
            }
            .frame(maxWidth: .infinity)
            .onAppear {
                focusedField = .code
            }

            // Error message
            if let error = errorMessage {
                AuthErrorBanner(message: error)
            }

            // Verify button
            Button {
                Task {
                    await handleVerification()
                }
            } label: {
                HStack {
                    if loadingAction == .credentials {
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

    private func submitCredentials() {
        guard !email.isEmpty, !password.isEmpty else { return }
        Task {
            if mode == .signIn {
                await handleEmailSignIn()
            } else {
                await handleEmailSignUp()
            }
        }
    }

    private func handleEmailSignIn() async {
        guard !email.isEmpty, !password.isEmpty else { return }

        loadingAction = .credentials
        errorMessage = nil

        do {
            try await authManager.signIn(email: email, password: password)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        loadingAction = nil
    }

    private func handleEmailSignUp() async {
        guard !email.isEmpty, !password.isEmpty else { return }

        loadingAction = .credentials
        errorMessage = nil

        do {
            let needsVerification = try await authManager.signUp(email: email, password: password)
            if needsVerification {
                withAnimation {
                    step = .verification
                }
            } else {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        loadingAction = nil
    }

    private func handleVerification() async {
        guard verificationCode.count == 6 else { return }

        loadingAction = .credentials
        errorMessage = nil

        do {
            try await authManager.verifyEmailCode(email: email, code: verificationCode)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        loadingAction = nil
    }

    private func handleResendCode() async {
        errorMessage = nil

        do {
            try await authManager.resendSignupCode(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleAppleSignIn() async {
        loadingAction = .apple
        errorMessage = nil

        do {
            try await authManager.signInWithApple()
            dismiss()
        } catch let error as ASAuthorizationError where error.code == .canceled {
            // User dismissed the Apple sheet - not an error
        } catch {
            errorMessage = error.localizedDescription
        }

        loadingAction = nil
    }

    private func handleGoogleSignIn() async {
        loadingAction = .google
        errorMessage = nil

        do {
            try await authManager.signInWithGoogle()
            dismiss()
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            // User closed the browser sheet - not an error
        } catch {
            errorMessage = error.localizedDescription
        }

        loadingAction = nil
    }
}

// MARK: - Error Banner

private struct AuthErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
        }
        .font(.caption)
        .foregroundStyle(.red)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Apple Sign In Button
// Follows Apple's HIG for custom Sign in with Apple buttons: system logo,
// adaptive black-on-white / white-on-black, same prominence as other providers.

struct AppleSignInButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let isLoading: Bool
    let action: () -> Void

    private var fillColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var textColor: Color {
        colorScheme == .dark ? .black : .white
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                } else {
                    Image(systemName: "applelogo")
                        .font(.system(size: 17, weight: .medium))

                    Text("Sign in with Apple")
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(fillColor)
            .cornerRadius(8)
        }
        .disabled(isLoading)
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
                        .tint(textColor)
                } else {
                    GoogleLogo()
                        .frame(width: 20, height: 20)

                    Text("Continue with Google")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(textColor)
                }
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
