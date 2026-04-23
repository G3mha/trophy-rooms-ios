import Foundation
import SwiftUI
import Combine

@MainActor
final class AdminPresentationContext: ObservableObject {
    @Published var isShowingDashboard = false

    func presentDashboard() {
        isShowingDashboard = true
    }

    func dismissDashboard() {
        isShowingDashboard = false
    }
}
