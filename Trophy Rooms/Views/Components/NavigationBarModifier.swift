import SwiftUI
import ClerkKit
import ClerkKitUI

struct NavigationBarModifier: ViewModifier {
    @Environment(Clerk.self) private var clerk
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
                if clerk.user != nil {
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
                            ProfileImage(imageUrl: clerk.user?.imageUrl)
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
    @Environment(Clerk.self) private var clerk
    @Environment(\.dismiss) private var dismiss
    @StateObject private var adminViewModel = AdminViewModel()
    @State private var isSigningOut = false

    var body: some View {
        NavigationStack {
            List {
                // Profile header section
                Section {
                    if let user = clerk.user {
                        VStack(spacing: 16) {
                            ProfileImage(imageUrl: user.imageUrl, size: 80)

                            VStack(spacing: 4) {
                                if let firstName = user.firstName, let lastName = user.lastName {
                                    Text("\(firstName) \(lastName)")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                } else if let firstName = user.firstName {
                                    Text(firstName)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }

                                Text(user.primaryEmailAddress?.emailAddress ?? "")
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
                        NavigationLink {
                            AdminDashboardView()
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
                    .disabled(isSigningOut)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .task {
                await adminViewModel.checkAdminStatus()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func signOut() async {
        isSigningOut = true
        do {
            try await clerk.auth.signOut()
            dismiss()
        } catch {
            print("Sign out error: \(error)")
        }
        isSigningOut = false
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
