import SwiftUI
import Clerk

@main
struct TrophyRoomsApp: App {
    @State private var clerk = Clerk.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.clerk, clerk)
                .task {
                    if let publishableKey = Bundle.main.object(forInfoDictionaryKey: "CLERK_PUBLISHABLE_KEY") as? String,
                       !publishableKey.isEmpty {
                        clerk.configure(publishableKey: publishableKey)
                        try? await clerk.load()
                    }
                }
                .onOpenURL { url in
                    // Handle OAuth callback from Clerk
                    Task {
                        await clerk.handleUrl(url)
                    }
                }
        }
    }
}
