import Foundation
import SwiftUI
import Combine

/// Observable context for managing inline admin actions
/// Tracks the current entity being viewed for contextual admin actions
class InlineAdminContext: ObservableObject {
    @Published var currentEntity: AdminContextEntity?

    /// Reference to the AdminViewModel for checking admin access
    weak var adminViewModel: AdminViewModel?

    /// Whether the current user can access admin features
    var canAccessAdmin: Bool {
        adminViewModel?.canAccessAdmin ?? false
    }

    /// Set the current entity being viewed
    @MainActor
    func setCurrentEntity(_ entity: AdminContextEntity) {
        // Only update if different to avoid unnecessary re-renders
        if currentEntity != entity {
            currentEntity = entity
        }
    }

    /// Clear the current entity (e.g., when navigating away)
    @MainActor
    func clearEntity() {
        currentEntity = nil
    }

    /// Clear entity only if it matches the given ID
    /// Prevents clearing when navigating to a child detail view
    @MainActor
    func clearEntityIfMatches(id: String) {
        if currentEntity?.id == id {
            clearEntity()
        }
    }
}
