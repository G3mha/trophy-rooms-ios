import Foundation

extension AdminAchievementsViewModel {
    func performAchievementMutation<T>(
        fallback: T,
        operation: () async throws -> T
    ) async -> T {
        resetMessages()

        do {
            return try await operation()
        } catch {
            setErrorMessage(error.localizedDescription)
            return fallback
        }
    }

    func resetMessages() {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }
    }

    func setErrorMessage(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
        }
    }

    func setSuccessMessage(_ message: String) {
        DispatchQueue.main.async {
            self.successMessage = message
        }
    }
}
