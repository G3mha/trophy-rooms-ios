import SwiftUI

@main
struct TrophyRoomsApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var inlineAdminContext = InlineAdminContext()
    @StateObject private var adminPresentationContext = AdminPresentationContext()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(inlineAdminContext)
                .environmentObject(adminPresentationContext)
                .onOpenURL { url in
                    AuthManager.shared.handleDeepLink(url)
                }
        }
    }
}
