import Foundation
import Combine

class AdminDLCsViewModel: ObservableObject {
    @Published var dlcs: [DLC] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    func fetchDLCs(gameFamilyId: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetDLCs($gameFamilyId: ID!) {
            dlcs(gameFamilyId: $gameFamilyId) {
                id
                name
                slug
                type
                description
                coverUrl
                effectiveCoverUrl
                releaseDate
                price
                gameFamilyId
                gameFamily {
                    id
                    title
                    slug
                }
                achievementSetCount
            }
        }
        """

        do {
            let response: DLCsResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["gameFamilyId": gameFamilyId]
            )
            DispatchQueue.main.async {
                self.dlcs = response.dlcs
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func createDLC(
        gameFamilyId: String,
        name: String,
        slug: String,
        type: DLCType,
        description: String?,
        coverUrl: String?,
        price: Double?
    ) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation CreateDLC($input: CreateDLCInput!) {
            createDLC(input: $input) {
                success
                dlc {
                    id
                    name
                    slug
                    type
                    description
                    coverUrl
                    effectiveCoverUrl
                    price
                    gameFamilyId
                }
            }
        }
        """

        var input: [String: Any] = [
            "gameFamilyId": gameFamilyId,
            "name": name,
            "slug": slug,
            "type": type.rawValue
        ]

        if let description = description, !description.isEmpty {
            input["description"] = description
        }
        if let coverUrl = coverUrl, !coverUrl.isEmpty {
            input["coverUrl"] = coverUrl
        }
        if let price = price {
            input["price"] = price
        }

        do {
            let response: CreateDLCResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["input": input]
            )
            if response.createDLC.success {
                await fetchDLCs(gameFamilyId: gameFamilyId)
                DispatchQueue.main.async {
                    self.successMessage = "DLC created successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create DLC"
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

    func updateDLC(
        id: String,
        gameFamilyId: String,
        name: String,
        slug: String,
        type: DLCType,
        description: String?,
        coverUrl: String?,
        price: Double?
    ) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation UpdateDLC($id: ID!, $input: UpdateDLCInput!) {
            updateDLC(id: $id, input: $input) {
                success
                dlc {
                    id
                    name
                    slug
                    type
                    description
                    coverUrl
                    effectiveCoverUrl
                    price
                    gameFamilyId
                }
            }
        }
        """

        var input: [String: Any] = [
            "name": name,
            "slug": slug,
            "type": type.rawValue
        ]

        if let description = description {
            input["description"] = description
        }
        if let coverUrl = coverUrl {
            input["coverUrl"] = coverUrl
        }
        if let price = price {
            input["price"] = price
        }

        do {
            let response: UpdateDLCResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id, "input": input]
            )
            if response.updateDLC.success {
                await fetchDLCs(gameFamilyId: gameFamilyId)
                DispatchQueue.main.async {
                    self.successMessage = "DLC updated successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update DLC"
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

    func deleteDLC(id: String, gameFamilyId: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation DeleteDLC($id: ID!) {
            deleteDLC(id: $id) {
                success
                deletedId
            }
        }
        """

        do {
            let response: DeleteDLCResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            if response.deleteDLC.success {
                DispatchQueue.main.async {
                    self.dlcs.removeAll { $0.id == id }
                    self.successMessage = "DLC deleted successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete DLC"
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

    func bulkDeleteDLCs(ids: [String], gameFamilyId: String) async -> Int {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation BulkDeleteDLCs($ids: [ID!]!) {
            bulkDeleteDLCs(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        do {
            let response: BulkDeleteDLCsResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["ids": ids]
            )
            if response.bulkDeleteDLCs.success {
                DispatchQueue.main.async {
                    self.dlcs.removeAll { ids.contains($0.id) }
                    self.successMessage = "Deleted \(response.bulkDeleteDLCs.deletedCount) DLC(s)"
                }
                return response.bulkDeleteDLCs.deletedCount
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete DLCs"
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
