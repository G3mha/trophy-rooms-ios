import SwiftUI

@main
struct TrophyRoomsApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var inlineAdminContext = InlineAdminContext()
    @StateObject private var adminPresentationContext = AdminPresentationContext()

    init() {
        // Cabinet identity on every screen header: poster display type for
        // large titles, bone-tinted (see .claude/skills/trophy-cabinet-design)
        let bone = UIColor(red: 0.937, green: 0.906, blue: 0.824, alpha: 1)
        if let anton = UIFont(name: "Anton-Regular", size: 34) {
            UINavigationBar.appearance().largeTitleTextAttributes = [
                .font: anton,
                .foregroundColor: bone,
            ]
        }
        if let antonSmall = UIFont(name: "Anton-Regular", size: 17) {
            UINavigationBar.appearance().titleTextAttributes = [
                .font: antonSmall,
                .foregroundColor: bone,
            ]
        }
    }

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
