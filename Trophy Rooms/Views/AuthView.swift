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
                // One cabinet panel with the title inside it, standing on a
                // lit shelf edge - the same frame as the web sign-in card
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text(headerTitle)
                                .font(Cabinet.display(36))
                                .textCase(.uppercase)
                                .foregroundStyle(Cabinet.bone)
                                .shadow(color: Cabinet.shadowRed.opacity(0.85), radius: 0, x: 3, y: 3)
                                .multilineTextAlignment(.center)
                                .contentTransition(.opacity)

                            if step == .verification {
                                Text("We sent a verification code to \(email).")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.bottom, 8)

                        if step == .verification {
                            verificationView
                        } else {
                            formView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 22)

                    CabinetShelfEdge()
                }
                .background(CabinetPanelBackground())
                .clipShape(panelShape)
                .overlay(panelShape.strokeBorder(Cabinet.brass.opacity(0.3), lineWidth: 1))
                // Print-style hard shadow, never blurred
                .background(panelShape.fill(Cabinet.ink.opacity(0.6)).offset(x: 6, y: 6))
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .cabinetCanvas()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Cabinet.bone)
                }
            }
        }
        // The cabinet is always dark; keeps the keyboard and provider
        // buttons on their dark variants even when the phone is in light mode
        .preferredColorScheme(.dark)
        .presentationDragIndicator(.visible)
    }

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
    }

    // MARK: - Header

    private var headerTitle: String {
        switch (mode, step) {
        case (.signIn, _): return "Sign in"
        case (.signUp, .form): return "Create account"
        case (.signUp, .verification): return "Verify your email"
        }
    }

    // MARK: - Form View

    private var formView: some View {
        VStack(spacing: 16) {
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

            // "or" with a brass hairline on each side
            HStack(spacing: 14) {
                Rectangle()
                    .fill(Cabinet.brass.opacity(0.2))
                    .frame(height: 1)
                Text("or")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Rectangle()
                    .fill(Cabinet.brass.opacity(0.2))
                    .frame(height: 1)
            }
            .padding(.vertical, 4)

            CabinetField(label: "Email", isFocused: focusedField == .email) {
                TextField("you@example.com", text: $email)
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

            VStack(alignment: .leading, spacing: 6) {
                CabinetField(label: "Password", isFocused: focusedField == .password) {
                    HStack(spacing: 10) {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
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
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                    }
                }

                if mode == .signUp {
                    Text("Must be at least 8 characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                if loadingAction == .credentials {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(mode == .signIn ? "Sign In" : "Create Account")
                }
            }
            .buttonStyle(CabinetPrimaryButtonStyle())
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .padding(.top, 4)

            // Switch mode
            HStack(spacing: 4) {
                Text(mode == .signIn ? "Don't have an account?" : "Already have an account?")
                    .foregroundStyle(.secondary)

                Button(mode == .signIn ? "Sign up" : "Sign in") {
                    Motion.animate {
                        mode = mode == .signIn ? .signUp : .signIn
                        errorMessage = nil
                    }
                }
                .foregroundStyle(Cabinet.brassLight)
                .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.top, 6)
        }
    }

    // MARK: - Verification View

    private var verificationView: some View {
        VStack(spacing: 20) {
            // Code boxes over an invisible field, so system
            // one-time-code autofill and the number pad both work
            ZStack {
                TextField("", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($focusedField, equals: .code)
                    // Clear text and caret rather than near-zero opacity: the
                    // Mail code suggestion wouldn't fill a near-invisible field
                    .foregroundStyle(.clear)
                    .tint(.clear)
                    .onChange(of: verificationCode) {
                        verificationCode = String(verificationCode.filter(\.isNumber).prefix(AuthManager.emailCodeLength))
                        if verificationCode.count == AuthManager.emailCodeLength {
                            Task {
                                await handleVerification()
                            }
                        }
                    }

                HStack(spacing: 8) {
                    ForEach(0..<AuthManager.emailCodeLength, id: \.self) { index in
                        let digits = Array(verificationCode)
                        let isCursor = index == verificationCode.count && focusedField == .code

                        Text(index < digits.count ? String(digits[index]) : " ")
                            .font(.title2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(Cabinet.bone)
                            // Shrinks below 44 so every box fits a narrow phone
                            .frame(maxWidth: 44)
                            .frame(height: 54)
                            .background(
                                Cabinet.ink.opacity(0.55),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(
                                        isCursor ? Cabinet.brass : Cabinet.brass.opacity(0.24),
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
                if loadingAction == .credentials {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Verify Email")
                }
            }
            .buttonStyle(CabinetPrimaryButtonStyle())
            .disabled(isLoading || verificationCode.count < AuthManager.emailCodeLength)

            VStack(spacing: 10) {
                HStack(spacing: 4) {
                    Text("Didn't receive a code?")
                        .foregroundStyle(.secondary)

                    Button("Resend") {
                        Task {
                            await handleResendCode()
                        }
                    }
                    .foregroundStyle(Cabinet.brassLight)
                    .fontWeight(.semibold)
                }

                Button("Back to sign up") {
                    Motion.animate {
                        step = .form
                        verificationCode = ""
                        errorMessage = nil
                    }
                }
                .foregroundStyle(.secondary)
            }
            .font(.subheadline)
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
                Motion.animate {
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
        guard verificationCode.count == AuthManager.emailCodeLength else { return }

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

// MARK: - Cabinet form pieces
// Mirrors the web auth card (trophy-rooms-web/src/components/auth).

/// Labeled input on a dark inset well, brass border that brightens on focus
private struct CabinetField<Content: View>: View {
    let label: String
    let isFocused: Bool
    @ViewBuilder let content: Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Cabinet.bone)

            content
                .textFieldStyle(.plain)
                .tint(Cabinet.brass)
                .padding(.horizontal, 14)
                .frame(minHeight: 46)
                .background(Cabinet.ink.opacity(0.55), in: shape)
                .overlay(
                    shape.strokeBorder(isFocused ? Cabinet.brass : Cabinet.brass.opacity(0.24), lineWidth: 1)
                )
                // Soft brass focus ring outside the border
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Cabinet.brass.opacity(isFocused ? 0.22 : 0), lineWidth: 3)
                        .padding(-3)
                )
                .cabinetAnimation(.easeOut(duration: 0.15), value: isFocused)
        }
    }
}

/// Crimson call to action with a print-style hard shadow that the button
/// presses into
private struct CabinetPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)
        let press: CGFloat = configuration.isPressed ? 2 : 0

        configuration.label
            .font(.body.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(Cabinet.crimson, in: shape)
            .offset(x: press, y: press)
            .background(shape.fill(Cabinet.shadowRed.opacity(0.85)).offset(x: 4, y: 4))
            .opacity(isEnabled ? 1 : 0.55)
            .contentShape(shape)
            .cabinetAnimation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Walnut panel lit by a warm pool of light from above
private struct CabinetPanelBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Cabinet.walnut, Color(red: 0.106, green: 0.067, blue: 0.031)], // -> #1b1108
                startPoint: .top,
                endPoint: .bottom
            )
            EllipticalGradient(
                colors: [Cabinet.amber.opacity(0.12), .clear],
                center: .top,
                startRadiusFraction: 0,
                endRadiusFraction: 0.75
            )
        }
    }
}

/// Lit wooden shelf edge the panel stands on
private struct CabinetShelfEdge: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.910, green: 0.835, blue: 0.675), location: 0),    // #e8d5ac
                .init(color: Color(red: 0.690, green: 0.553, blue: 0.329), location: 0.22), // #b08d54
                .init(color: Color(red: 0.361, green: 0.247, blue: 0.133), location: 0.6),  // #5c3f22
                .init(color: Color(red: 0.110, green: 0.067, blue: 0.031), location: 1),    // #1c1108
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 10)
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
        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Apple Sign In Button
// Follows Apple's HIG for custom Sign in with Apple buttons: system logo,
// black style with an outline (as on web), same size and prominence as Google.
// A white button would be the brightest thing on the walnut panel.

struct AppleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    private let fillColor = Color.black
    private let textColor = Color.white

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                } else {
                    Image(systemName: "applelogo")
                        .font(.system(size: 16, weight: .medium))

                    Text("Sign in with Apple")
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(fillColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Cabinet.Tint.muted, lineWidth: 1)
            )
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
