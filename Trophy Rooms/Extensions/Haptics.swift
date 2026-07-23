import UIKit

/// Small helpers for notification-style haptic feedback from imperative flows
/// (mutation success handlers) where a SwiftUI `.sensoryFeedback` trigger has
/// no stable state to observe.
enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
