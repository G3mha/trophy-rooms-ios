import Foundation
import Combine

class AdminPlatformsViewModel: ObservableObject {
    @Published var platforms: [AdminPlatform] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    func fetchPlatforms() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetPlatforms {
            platforms {
                id
                name
                slug
            }
        }
        """

        do {
            let response: AdminPlatformsResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.platforms = response.platforms
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func createPlatform(name: String, slug: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation CreatePlatform($input: CreatePlatformInput!) {
            createPlatform(input: $input) {
                success
                platform {
                    id
                    name
                    slug
                }
            }
        }
        """

        let variables: [String: Any] = [
            "input": [
                "name": name,
                "slug": slug
            ]
        ]

        do {
            let response: CreatePlatformResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.createPlatform.success {
                await fetchPlatforms()
                DispatchQueue.main.async {
                    self.successMessage = "Platform created successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create platform"
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

    func updatePlatform(id: String, name: String, slug: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation UpdatePlatform($id: ID!, $input: UpdatePlatformInput!) {
            updatePlatform(id: $id, input: $input) {
                success
                platform {
                    id
                    name
                    slug
                }
            }
        }
        """

        let variables: [String: Any] = [
            "id": id,
            "input": [
                "name": name,
                "slug": slug
            ]
        ]

        do {
            let response: UpdatePlatformResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.updatePlatform.success {
                await fetchPlatforms()
                DispatchQueue.main.async {
                    self.successMessage = "Platform updated successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update platform"
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

    func deletePlatform(id: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation DeletePlatform($id: ID!) {
            deletePlatform(id: $id) {
                success
            }
        }
        """

        do {
            let response: DeletePlatformResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            if response.deletePlatform.success {
                DispatchQueue.main.async {
                    self.platforms.removeAll { $0.id == id }
                    self.successMessage = "Platform deleted successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete platform"
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

    func bulkDeletePlatforms(ids: [String]) async -> Int {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation BulkDeletePlatforms($ids: [ID!]!) {
            bulkDeletePlatforms(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        do {
            let response: BulkDeletePlatformsResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["ids": ids]
            )
            if response.bulkDeletePlatforms.success {
                DispatchQueue.main.async {
                    self.platforms.removeAll { ids.contains($0.id) }
                    self.successMessage = "Deleted \(response.bulkDeletePlatforms.deletedCount) platform(s)"
                }
                return response.bulkDeletePlatforms.deletedCount
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete platforms"
                }
                return 0
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return 0
        }
    }
}
