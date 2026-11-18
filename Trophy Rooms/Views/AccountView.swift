import SwiftUI
import AuthenticationServices
import Supabase

/// Email, password and linked sign-in methods; the iOS side of the web
/// /account page
struct AccountView: View {
    private static let providers: [(provider: Provider, label: String)] = [
        (.google, "Google"),
        (.apple, "Apple"),
    ]
    private static let minPasswordLength = 8

    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    // Fetched from the server (not the session) so identities and a pending
    // email change are current after linking, unlinking, or confirming
    @State private var user: User?
    @State private var loadError: String?

    @State private var newEmail = ""
    @State private var emailError: String?
    @State private var savingEmail = false

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var passwordError: String?
    @State private var passwordSaved = false
    @State private var savingPassword = false
    // Set while Supabase wants an emailed code (sign-in over 24 hours old)
    @State private var codePrompt: String?
    @State private var code = ""

    @State private var providerError: String?
    @State private var busyProvider: Provider?

    var body: some View {
        Group {
            if let user {
                form(for: user)
            } else if let loadError {
                ContentUnavailableView(
                    "Couldn't Load Account",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else {
                CabinetLoadingView("Loading account")
            }
        }
        .navigationTitle("Account Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadUser() }
        // Linking, email changes, and confirmation deep links all end in an
        // auth event, so one reload path covers them
        .onReceive(NotificationCenter.default.publisher(for: .init("AuthUserDidChange"))) { _ in
            Task { await loadUser() }
        }
    }

    private func form(for user: User) -> some View {
        let identities = user.identities ?? []

        return List {
            Section {
                Text(user.email ?? "")
                TextField("New email", text: $newEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(savingEmail)
                Button {
                    Task { await changeEmail() }
                } label: {
                    if savingEmail { ProgressView() } else { Text("Change Email") }
                }
                .disabled(savingEmail || trimmedEmail.isEmpty)
            } header: {
                Text("Email")
            } footer: {
                if let emailError {
                    Text(emailError).foregroundStyle(.red)
                } else if let pending = user.newEmail {
                    Text("Waiting for confirmation to switch to \(pending). Open the links sent to both addresses.")
                }
            }

            Section {
                if codePrompt != nil {
                    TextField("Code", text: $code)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .disabled(savingPassword)
                        .onChange(of: code) {
                            code = String(code.filter(\.isNumber).prefix(AuthManager.emailCodeLength))
                            if code.count == AuthManager.emailCodeLength {
                                Task { await savePassword(nonce: code) }
                            }
                        }
                    Button {
                        Task { await savePassword(nonce: code) }
                    } label: {
                        if savingPassword { ProgressView() } else { Text("Confirm") }
                    }
                    .disabled(savingPassword || code.count < AuthManager.emailCodeLength)
                    Button("Resend Code") {
                        Task { await sendCode(resend: true) }
                    }
                    .disabled(savingPassword)
                    Button("Cancel") {
                        codePrompt = nil
                        code = ""
                        passwordError = nil
                    }
                    .disabled(savingPassword)
                } else {
                    SecureField("New password", text: $password)
                        .textContentType(.newPassword)
                        .disabled(savingPassword)
                    SecureField("Confirm new password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .disabled(savingPassword)
                    Button {
                        Task { await changePassword() }
                    } label: {
                        if savingPassword { ProgressView() } else { Text("Save Password") }
                    }
                    .disabled(savingPassword || password.isEmpty || confirmPassword.isEmpty)
                }
            } header: {
                Text("Password")
            } footer: {
                if let passwordError {
                    Text(passwordError).foregroundStyle(.red)
                } else if let codePrompt {
                    Text(codePrompt)
                } else if passwordSaved {
                    Text("Password saved.")
                } else {
                    Text("At least \(Self.minPasswordLength) characters.")
                }
            }

            Section {
                ForEach(Self.providers, id: \.label) { entry in
                    let provider = entry.provider
                    let identity = identities.first { $0.provider == provider.rawValue }
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.label)
                            if let email = identity?.identityData?["email"]?.stringValue {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if busyProvider == provider {
                            ProgressView()
                        } else if let identity {
                            Button("Disconnect") {
                                Task { await disconnect(identity) }
                            }
                            // Supabase refuses to remove the last way to sign in
                            .disabled(identities.count < 2 || busyProvider != nil)
                        } else {
                            Button("Connect") {
                                Task { await connect(provider) }
                            }
                            .disabled(busyProvider != nil)
                        }
                    }
                    // Keeps the tap on the button instead of the whole row
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            } header: {
                Text("Sign-in Methods")
            } footer: {
                if let providerError {
                    Text(providerError).foregroundStyle(.red)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var trimmedEmail: String {
        newEmail.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Actions

    private func loadUser() async {
        do {
            user = try await authManager.currentUser()
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func changeEmail() async {
        savingEmail = true
        emailError = nil
        do {
            try await authManager.changeEmail(to: trimmedEmail)
            newEmail = ""
            Haptics.success()
        } catch {
            emailError = error.localizedDescription
        }
        savingEmail = false
    }

    private func changePassword() async {
        passwordSaved = false
        guard password.count >= Self.minPasswordLength else {
            passwordError = "Use at least \(Self.minPasswordLength) characters."
            return
        }
        guard password == confirmPassword else {
            passwordError = "Passwords don't match."
            return
        }
        await savePassword()
    }

    private func savePassword(nonce: String? = nil) async {
        // Autofill can fire the code field's auto-submit twice
        guard !savingPassword else { return }
        savingPassword = true
        passwordError = nil
        do {
            try await authManager.changePassword(to: password, nonce: nonce)
            password = ""
            confirmPassword = ""
            codePrompt = nil
            code = ""
            passwordSaved = true
            Haptics.success()
        } catch let error as AuthError where error.errorCode == .reauthenticationNeeded {
            await sendCode(resend: false)
        } catch {
            // A wrong or expired code comes back here with Supabase's message
            passwordError = error.localizedDescription
            code = ""
        }
        savingPassword = false
    }

    private func sendCode(resend: Bool) async {
        passwordError = nil
        code = ""
        let email = user?.email ?? "your email"
        do {
            try await authManager.sendReauthenticationCode()
            codePrompt = resend
                ? "We sent a new code to \(email)."
                : "Enter the code we emailed to \(email) to confirm it's you."
        } catch {
            passwordError = error.localizedDescription
        }
    }

    private func connect(_ provider: Provider) async {
        busyProvider = provider
        providerError = nil
        do {
            if provider == .apple {
                try await authManager.linkApple()
            } else {
                try await authManager.linkGoogle { url in
                    try await webAuthenticationSession.authenticate(
                        using: url,
                        callback: .customScheme(AuthManager.callbackURL.scheme ?? ""),
                        additionalHeaderFields: [:]
                    )
                }
            }
            Haptics.success()
        } catch let error as ASAuthorizationError where error.code == .canceled {
            // Dismissed the Apple sheet - not an error
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            // Closed the Google page - not an error
        } catch {
            providerError = error.localizedDescription
        }
        busyProvider = nil
    }

    private func disconnect(_ identity: UserIdentity) async {
        busyProvider = Provider(rawValue: identity.provider)
        providerError = nil
        do {
            try await authManager.unlink(identity)
            // Unlinking emits no auth event, so reload by hand
            await loadUser()
            Haptics.success()
        } catch {
            providerError = error.localizedDescription
        }
        busyProvider = nil
    }
}
