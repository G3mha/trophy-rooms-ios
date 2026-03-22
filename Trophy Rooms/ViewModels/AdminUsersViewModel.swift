import Foundation
import Combine

class AdminUsersViewModel: ObservableObject {
    @Published var users: [AdminUser] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var searchText: String = ""

    var filteredUsers: [AdminUser] {
        if searchText.isEmpty {
            return users
        }
        return users.filter { user in
            user.email.localizedCaseInsensitiveContains(searchText) ||
            (user.name?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    func searchUsers(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            DispatchQueue.main.async {
                self.users = []
            }
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let graphqlQuery = """
        query SearchUsers($search: String, $first: Int) {
            users(search: $search, first: $first) {
                edges {
                    node {
                        id
                        email
                        name
                        role
                    }
                }
            }
        }
        """

        let variables: [String: Any] = [
            "search": query,
            "first": 50
        ]

        do {
            let response: AdminUsersResponse = try await NetworkService.shared.fetch(
                query: graphqlQuery,
                variables: variables
            )
            DispatchQueue.main.async {
                self.users = response.users.edges.map { $0.node }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func setUserRole(userId: String, role: UserRole) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation SetUserRole($userId: ID!, $role: UserRole!) {
            setUserRole(userId: $userId, role: $role) {
                success
                user {
                    id
                    email
                    name
                    role
                }
            }
        }
        """

        let variables: [String: Any] = [
            "userId": userId,
            "role": role.rawValue
        ]

        do {
            let response: SetUserRoleResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.setUserRole.success {
                if let updatedUser = response.setUserRole.user {
                    DispatchQueue.main.async {
                        if let index = self.users.firstIndex(where: { $0.id == userId }) {
                            self.users[index] = updatedUser
                        }
                        self.successMessage = "Role updated successfully"
                    }
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update role"
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
}
