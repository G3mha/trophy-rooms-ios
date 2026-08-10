import SwiftUI

struct NavigationBarModifier: ViewModifier {
    @EnvironmentObject private var authManager: AuthManager
    let title: String
    var showAuthBinding: Binding<Bool>?
    var shareURL: URL?
    @State private var showShareSheet = false
    @State private var showUserMenu = false

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if authManager.isSignedIn {
                    if shareURL != nil {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                showShareSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showUserMenu = true
                        } label: {
                            ProfileImage(imageUrl: authManager.avatarURL)
                        }
                    }
                } else if let binding = showAuthBinding {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Sign In") {
                            binding.wrappedValue = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showUserMenu) {
                UserMenuSheet()
            }
    }
}

// Custom profile image view
private struct ProfileImage: View {
    let imageUrl: String?
    var size: CGFloat = 30

    var body: some View {
        if let urlString = imageUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: size, height: size)
                .foregroundColor(.gray)
        }
    }
}

// User menu sheet
private struct UserMenuSheet: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var adminViewModel: AdminViewModel
    @EnvironmentObject private var adminPresentationContext: AdminPresentationContext
    @State private var isSigningOut = false
    @State private var isDeletingAccount = false
    @State private var showDeleteConfirmation = false
    @State private var deleteErrorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                // Profile header section
                Section {
                    if authManager.isSignedIn {
                        VStack(spacing: 16) {
                            ProfileImage(imageUrl: authManager.avatarURL, size: 80)

                            VStack(spacing: 4) {
                                if let name = authManager.displayName {
                                    Text(name)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }

                                Text(authManager.userEmail ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                    }
                }

                // Admin section
                if adminViewModel.canAccessAdmin {
                    Section {
                        Button {
                            adminPresentationContext.presentDashboard()
                            dismiss()
                        } label: {
                            Label {
                                Text("Admin Dashboard")
                            } icon: {
                                Image(systemName: "gearshape.2.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }

                // Sign out section
                Section {
                    Button(role: .destructive) {
                        Task {
                            await signOut()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSigningOut {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Sign Out")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSigningOut || isDeletingAccount)
                }

                // Account deletion (App Store guideline 5.1.1 requires in-app deletion)
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            if isDeletingAccount {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Delete Account")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSigningOut || isDeletingAccount)
                } footer: {
                    if let deleteErrorMessage {
                        Text(deleteErrorMessage)
                            .foregroundStyle(.red)
                    } else {
                        Text("Permanently deletes your account, collection, library, and play history.")
                    }
                }
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text("This permanently deletes your account and all of your collection, library, trophy, and play journal data. This cannot be undone.")
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func signOut() async {
        isSigningOut = true
        await authManager.signOut()
        dismiss()
        isSigningOut = false
    }

    private func deleteAccount() async {
        isDeletingAccount = true
        deleteErrorMessage = nil

        let mutation = """
        mutation DeleteMyAccount {
            deleteMyAccount {
                success
                error {
                    message
                }
            }
        }
        """

        do {
            let response: DeleteMyAccountResponse = try await NetworkService.shared.fetch(query: mutation)
            if response.deleteMyAccount.success {
                // Backend removed both app data and the auth identity;
                // drop the local session and close the sheet
                await authManager.signOut()
                dismiss()
            } else {
                deleteErrorMessage = response.deleteMyAccount.error?.message ?? "Could not delete your account. Please try again."
            }
        } catch {
            deleteErrorMessage = error.localizedDescription
        }

        isDeletingAccount = false
    }
}

private struct DeleteMyAccountResponse: Decodable {
    let deleteMyAccount: DeleteMyAccountResult

    struct DeleteMyAccountResult: Decodable {
        let success: Bool
        let error: MutationError?
    }

    struct MutationError: Decodable {
        let message: String
    }
}

extension View {
    func navigationBar(title: String) -> some View {
        modifier(NavigationBarModifier(title: title, showAuthBinding: nil, shareURL: nil))
    }

    func navigationBar(title: String, showAuth: Binding<Bool>) -> some View {
        modifier(NavigationBarModifier(title: title, showAuthBinding: showAuth, shareURL: nil))
    }

    func navigationBar(title: String, shareURL: URL?) -> some View {
        modifier(NavigationBarModifier(title: title, showAuthBinding: nil, shareURL: shareURL))
    }

    func navigationBar(title: String, showAuth: Binding<Bool>, shareURL: URL?) -> some View {
        modifier(NavigationBarModifier(title: title, showAuthBinding: showAuth, shareURL: shareURL))
    }
}
