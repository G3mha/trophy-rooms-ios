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
            .frame(width: 30, height: 30)
            .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.gray)
        }
    }
}

// User menu sheet - uses ClerkKitUI's UserButton for sign out
private struct UserMenuSheet: View {
    @Environment(Clerk.self) private var clerk
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let user = clerk.user {
                    VStack(spacing: 12) {
                        ProfileImage(imageUrl: user.imageUrl)
                            .scaleEffect(2)
                            .padding(.top, 20)

                        if let name = user.firstName {
                            Text(name)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        Text(user.primaryEmailAddress?.emailAddress ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    Spacer()

                    // Use ClerkKitUI's UserButton for proper sign out
                    UserButton()
                        .padding()

                    Spacer()
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
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
