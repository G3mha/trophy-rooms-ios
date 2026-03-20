import Foundation
import Combine

class AdminViewModel: ObservableObject {
    @Published var isAdmin = false
    @Published var isTrusted = false
    @Published var currentUser: CurrentUser?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var canAccessAdmin: Bool {
        isAdmin || isTrusted
    }

    func checkAdminStatus() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
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
                self.currentUser = response.me
                if let user = response.me {
                    self.isAdmin = user.role == .ADMIN
                    self.isTrusted = user.role == .TRUSTED || user.role == .ADMIN
                } else {
                    self.isAdmin = false
                    self.isTrusted = false
                }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isAdmin = false
                self.isTrusted = false
                self.isLoading = false
            }
        }
    }

    func reset() {
        DispatchQueue.main.async {
            self.isAdmin = false
            self.isTrusted = false
            self.currentUser = nil
        }
    }
}
