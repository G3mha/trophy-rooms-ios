import SwiftUI
import Clerk
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
    @Environment(\.clerk) private var clerk
    @Environment(\.dismiss) private var dismiss

    @State private var mode: AuthMode = .signIn
    @State private var step: AuthStep = .form
    @State private var email = ""
    @State private var password = ""
    @State private var verificationCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false

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
                .padding(.vertical, 14)
                .background(Color(red: 0.863, green: 0.078, blue: 0.235))
                .foregroundColor(.white)
                .cornerRadius(8)
                .fontWeight(.semibold)
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)

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
                .foregroundColor(Color(red: 0.863, green: 0.078, blue: 0.235))
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
                .padding(.vertical, 14)
                .background(Color(red: 0.863, green: 0.078, blue: 0.235))
                .foregroundColor(.white)
                .cornerRadius(8)
                .fontWeight(.semibold)
            }
            .disabled(isLoading || verificationCode.count < 6)
            .opacity(verificationCode.count < 6 ? 0.6 : 1)

            // Resend code
            HStack {
                Text("Didn't receive a code?")
                    .foregroundColor(.secondary)

                Button("Resend") {
                    Task {
                        await handleResendCode()
                    }
                }
                .foregroundColor(Color(red: 0.863, green: 0.078, blue: 0.235))
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
            let signIn = try await SignIn.create(strategy: .identifier(email, password: password))

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
            _ = try await SignUp.create(
                strategy: .standard(emailAddress: email, password: password)
            )

            try await clerk.client?.signUp?.prepareVerification(strategy: .emailCode)

            withAnimation {
                step = .verification
            }
        } catch {
            errorMessage = parseClerkError(error)
        }

        isLoading = false
    }

    private func handleVerification() async {
        guard verificationCode.count == 6 else { return }

        isLoading = true
        errorMessage = nil

        do {
            let signUp = try await clerk.client?.signUp?.attemptVerification(
                .emailCode(code: verificationCode)
            )

            if signUp?.status == .complete {
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
        errorMessage = nil

        do {
            try await clerk.client?.signUp?.prepareVerification(strategy: .emailCode)
        } catch {
            errorMessage = parseClerkError(error)
        }
    }

    private func handleGoogleSignIn() async {
        isLoading = true
        errorMessage = nil

        do {
            if mode == .signIn {
                _ = try await SignIn.create(strategy: .oauth(.google))
            } else {
                _ = try await SignUp.create(strategy: .oauth(.google))
            }
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

struct GoogleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    GoogleLogo()
                        .frame(width: 20, height: 20)
                }

                Text("Continue with Google")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
        .disabled(isLoading)
    }
}

// MARK: - Google Logo (Simplified G icon with Google colors)

struct GoogleLogo: View {
    var body: some View {
        ZStack {
            // Outer ring with Google colors
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.918, green: 0.263, blue: 0.208), // Red
                            Color(red: 0.984, green: 0.737, blue: 0.02),  // Yellow
                            Color(red: 0.204, green: 0.659, blue: 0.325), // Green
                            Color(red: 0.259, green: 0.522, blue: 0.957), // Blue
                            Color(red: 0.918, green: 0.263, blue: 0.208), // Red (loop)
                        ]),
                        center: .center
                    ),
                    lineWidth: 3
                )

            // White center
            Circle()
                .fill(Color.white)
                .padding(4)

            // G letter
            Text("G")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.259, green: 0.522, blue: 0.957))
        }
    }
}

#Preview {
    AuthView()
}
