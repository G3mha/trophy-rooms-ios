import Foundation

/// Protocol for admin ViewModels that handle CRUD operations
@MainActor
protocol AdminCRUDViewModel: LoadableViewModel {
    associatedtype Entity: Identifiable

    var items: [Entity] { get set }
    var successMessage: String? { get set }

    func fetch() async
}

extension AdminCRUDViewModel {
    /// Execute a mutation operation with automatic state management
    /// Returns true if successful, false otherwise
    func performMutation(_ operation: () async throws -> Bool) async -> Bool {
        errorMessage = nil
        successMessage = nil

        do {
            let success = try await operation()
            if !success {
                errorMessage = "Operation failed"
            }
            return success
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Remove items by IDs from the local list
    func removeItems(withIds ids: [String]) where Entity.ID == String {
        items.removeAll { ids.contains($0.id) }
    }

    /// Remove a single item by ID from the local list
    func removeItem(withId id: String) where Entity.ID == String {
        items.removeAll { $0.id == id }
    }

    /// Set a success message
    func setSuccess(_ message: String) {
        successMessage = message
    }

    /// Clear messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}

/// Protocol for form state management in admin forms
protocol AdminFormState {
    var isValid: Bool { get }
    func reset()
    mutating func populate(from entity: Any)
}
