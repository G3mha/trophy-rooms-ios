import Foundation

/// Protocol for ViewModels that handle async loading with standard state management
@MainActor
protocol LoadableViewModel: ObservableObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
}

extension LoadableViewModel {
    /// Execute an async operation with automatic loading and error state management
    /// Returns the result of the operation, or nil if it failed
    func performLoad<T>(_ operation: () async throws -> T) async -> T? {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await operation()
            isLoading = false
            return result
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return nil
        }
    }

    /// Execute an async operation without setting isLoading (for background refreshes)
    func performSilentLoad<T>(_ operation: () async throws -> T) async -> T? {
        errorMessage = nil

        do {
            return try await operation()
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Clear the error message
    func clearError() {
        errorMessage = nil
    }
}
