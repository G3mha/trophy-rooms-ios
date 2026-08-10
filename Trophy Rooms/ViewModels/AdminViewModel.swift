import Foundation
import Combine

class AdminViewModel: ObservableObject {
    private enum CacheKeys {
        static let isAdmin = "admin_view_model.is_admin"
        static let isTrusted = "admin_view_model.is_trusted"
    }

    @Published var isAdmin = false
    @Published var isTrusted = false
    @Published var currentUser: CurrentUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var canAccessAdmin: Bool {
        isAdmin || isTrusted
    }

    init() {
        isAdmin = UserDefaults.standard.bool(forKey: CacheKeys.isAdmin)
        isTrusted = UserDefaults.standard.bool(forKey: CacheKeys.isTrusted)
    }

    private func persistAccess() {
        UserDefaults.standard.set(isAdmin, forKey: CacheKeys.isAdmin)
        UserDefaults.standard.set(isTrusted, forKey: CacheKeys.isTrusted)
    }

    private func clearPersistedAccess() {
        UserDefaults.standard.removeObject(forKey: CacheKeys.isAdmin)
        UserDefaults.standard.removeObject(forKey: CacheKeys.isTrusted)
    }

    func checkAdminStatus() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        guard await AuthManager.shared.isSignedIn else {
            DispatchQueue.main.async {
                self.reset()
                self.isLoading = false
            }
            return
        }

        let query = """
        query GetMe {
            me {
                id
                role
            }
        }
        """

        do {
            let response: CurrentUserResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                if let user = response.me {
                    self.currentUser = user
                    self.isAdmin = user.role == .ADMIN
                    self.isTrusted = user.role == .TRUSTED || user.role == .ADMIN
                    self.persistAccess()
                } else {
                    self.errorMessage = "Unable to verify admin access right now."
                }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func reset() {
        DispatchQueue.main.async {
            self.isAdmin = false
            self.isTrusted = false
            self.currentUser = nil
            self.clearPersistedAccess()
        }
    }
}
