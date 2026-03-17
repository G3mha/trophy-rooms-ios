import SwiftUI
import ClerkKit

@main
struct TrophyRoomsApp: App {

    init() {
        let publishableKey = Bundle.main.object(forInfoDictionaryKey: "CLERK_PUBLISHABLE_KEY") as? String ?? ""

        let options = Clerk.Options(
            redirectConfig: .init(
                redirectUrl: "clerk.trophyrooms.org://callback",
                callbackUrlScheme: "clerk.trophyrooms.org"
            )
        )
        Clerk.configure(publishableKey: publishableKey, options: options)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(Clerk.shared)
        }
    }
}
