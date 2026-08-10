import Foundation
import Combine
import Supabase
import AuthenticationServices
import CryptoKit

/// Central Supabase auth state and flows. Replaces the Clerk SDK: views
/// observe `isSignedIn`, NetworkService pulls `accessToken()`, and the auth
/// sheet drives the sign-in methods.
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    let client: SupabaseClient

    @Published private(set) var session: Session?

    var isSignedIn: Bool { session != nil }
    var userId: String? { session?.user.id.uuidString.lowercased() }
    var userEmail: String? { session?.user.email }

    var displayName: String? {
        session?.user.userMetadata["full_name"]?.stringValue
            ?? session?.user.userMetadata["name"]?.stringValue
    }

    var avatarURL: String? {
        session?.user.userMetadata["avatar_url"]?.stringValue
            ?? session?.user.userMetadata["picture"]?.stringValue
    }

    private init() {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String ?? ""

        guard let url = URL(string: urlString) else {
            fatalError("SUPABASE_URL is not configured")
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: key)

        Task {
            await observeAuthChanges()
        }
    }

    private func observeAuthChanges() async {
        for await (_, session) in client.auth.authStateChanges {
            self.session = session
            NotificationCenter.default.post(name: .init("AuthUserDidChange"), object: nil)
        }
    }

    /// Current access token, refreshing the session if needed
    func accessToken() async -> String? {
        try? await client.auth.session.accessToken
    }

    // MARK: - Email + password

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    /// Returns true when the account still needs email verification
    func signUp(email: String, password: String) async throws -> Bool {
        let response = try await client.auth.signUp(email: email, password: password)
        return response.session == nil
    }

    func verifyEmailCode(email: String, code: String) async throws {
        try await client.auth.verifyOTP(email: email, token: code, type: .signup)
    }

    func resendSignupCode(email: String) async throws {
        try await client.auth.resend(email: email, type: .signup)
    }

    // MARK: - OAuth providers

    /// Web-based Google flow through the Supabase callback; the redirect URL
    /// must be allow-listed in Supabase Auth settings.
    func signInWithGoogle() async throws {
        try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: "trophyrooms://auth-callback")
        )
    }

    /// Fully native Sign in with Apple: system sheet, then the identity
    /// token is exchanged with Supabase (nonce-bound).
    func signInWithApple() async throws {
        let rawNonce = Self.randomNonceString()
        let credential = try await AppleCredentialController().requestCredential(
            nonceHash: Self.sha256(rawNonce)
        )

        guard
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            throw AuthManagerError.missingAppleToken
        }

        try await client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .apple,
                idToken: idToken,
                nonce: rawNonce
            )
        )
    }

    // MARK: - Session lifecycle

    func signOut() async {
        try? await client.auth.signOut()
    }

    /// Completes flows that return to the app via deep link (magic links)
    func handleDeepLink(_ url: URL) {
        Task {
            try? await client.auth.session(from: url)
        }
    }

    // MARK: - Nonce helpers

    private static func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length

        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status != errSecSuccess { continue }
            if random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

enum AuthManagerError: LocalizedError {
    case missingAppleToken

    var errorDescription: String? {
        switch self {
        case .missingAppleToken:
            return "Unable to retrieve the Apple identity token."
        }
    }
}

// MARK: - Apple credential controller

/// Runs the ASAuthorization flow and bridges it into async/await.
private final class AppleCredentialController: NSObject, ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {

    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    func requestCredential(nonceHash: String) async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.email, .fullName]
            request.nonce = nonceHash

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation?.resume(returning: credential)
        } else {
            continuation?.resume(throwing: AuthManagerError.missingAppleToken)
        }
        continuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        return scene?.keyWindow ?? ASPresentationAnchor()
    }
}
