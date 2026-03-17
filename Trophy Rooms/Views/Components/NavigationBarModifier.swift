import SwiftUI
import ClerkKit
import ClerkKitUI

struct NavigationBarModifier: ViewModifier {
    @Environment(Clerk.self) private var clerk
    let title: String
    var showAuthBinding: Binding<Bool>?

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if clerk.user != nil {
                        UserButton()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    } else if let binding = showAuthBinding {
                        Button("Sign In") {
                            binding.wrappedValue = true
                        }
                    }
                }
            }
    }
}

extension View {
    func navigationBar(title: String) -> some View {
        modifier(NavigationBarModifier(title: title, showAuthBinding: nil))
    }

    func navigationBar(title: String, showAuth: Binding<Bool>) -> some View {
        modifier(NavigationBarModifier(title: title, showAuthBinding: showAuth))
    }
}
