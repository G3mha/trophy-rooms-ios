import SwiftUI
import UIKit

/// Reduce Motion support.
///
/// iOS users who get motion sickness from animation turn on Settings >
/// Accessibility > Motion > Reduce Motion. Honouring it is what lets the App
/// Store listing claim "Reduced Motion" support, and it is what the setting
/// is for: the state change still happens, it just arrives without the
/// in-between frames.
///
/// Two entry points, because SwiftUI animates two ways:
/// - `.cabinetAnimation(_:value:)` replaces `.animation(_:value:)`
/// - `Motion.animate { }` replaces `withAnimation { }`
///
/// Both collapse to an instant change when the setting is on. Prefer these
/// over the raw SwiftUI calls anywhere the animation is decorative.
enum Motion {
    /// Whether the user has asked for reduced motion.
    ///
    /// Read from UIKit rather than the SwiftUI environment so it also works
    /// from imperative code (button actions, view models) where there is no
    /// `Environment` to read.
    static var isReduced: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// `withAnimation`, skipped when the user asked for reduced motion.
    @discardableResult
    static func animate<Result>(
        _ animation: Animation = .default,
        _ body: () throws -> Result
    ) rethrows -> Result {
        try withAnimation(isReduced ? nil : animation, body)
    }
}

// MARK: - Declarative

private struct MotionAwareAnimation<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

extension View {
    /// `.animation(_:value:)`, skipped when the user asked for reduced motion.
    func cabinetAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(MotionAwareAnimation(animation: animation, value: value))
    }
}
