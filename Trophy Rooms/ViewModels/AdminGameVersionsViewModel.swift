import Foundation
import Combine

class AdminGameVersionsViewModel: ObservableObject {
    @Published var versions: [GameVersion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    func fetchVersions(gameId: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetGameVersions($gameId: ID!) {
            gameVersions(gameId: $gameId) {
                id
                name
                slug
                description
                coverUrl
                effectiveCoverUrl
                releaseDate
                isDefault
                games {
                    id
                    title
                }
                dlcs {
                    id
                    name
                    slug
                    type
                }
                dlcCount
                achievementSetCount
            }
        }
        """

        do {
            let response: GameVersionsResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["gameId": gameId]
            )
            DispatchQueue.main.async {
                self.versions = response.gameVersions
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func createVersion(
        gameId: String,
        name: String,
        slug: String,
        description: String?,
        coverUrl: String?,
        dlcIds: [String]?,
        isDefault: Bool
    ) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation CreateGameVersion($input: CreateGameVersionInput!) {
            createGameVersion(input: $input) {
                success
                gameVersion {
                    id
                    name
                    slug
                    description
                    coverUrl
                    effectiveCoverUrl
                    isDefault
                    dlcs {
                        id
                        name
                    }
                }
            }
        }
        """

        var input: [String: Any] = [
            "gameIds": [gameId],
            "name": name,
            "slug": slug
        ]

        if let description = description, !description.isEmpty {
            input["description"] = description
        }
        if let coverUrl = coverUrl, !coverUrl.isEmpty {
            input["coverUrl"] = coverUrl
        }
        if let dlcIds = dlcIds, !dlcIds.isEmpty {
            input["dlcIds"] = dlcIds
        }
        if isDefault {
            input["isDefault"] = isDefault
        }

        do {
            let response: CreateGameVersionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["input": input]
            )
            if response.createGameVersion.success {
                await fetchVersions(gameId: gameId)
                DispatchQueue.main.async {
                    self.successMessage = "Version created successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create version"
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

    func updateVersion(
        id: String,
        gameId: String,
        name: String,
        slug: String,
        description: String?,
        coverUrl: String?,
        dlcIds: [String]?
    ) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation UpdateGameVersion($id: ID!, $input: UpdateGameVersionInput!) {
            updateGameVersion(id: $id, input: $input) {
                success
                gameVersion {
                    id
                    name
                    slug
                    description
                    coverUrl
                    effectiveCoverUrl
                    isDefault
                    dlcs {
                        id
                        name
                    }
                }
            }
        }
        """

        var input: [String: Any] = [
            "name": name,
            "slug": slug
        ]

        if let description = description {
            input["description"] = description
        }
        if let coverUrl = coverUrl {
            input["coverUrl"] = coverUrl
        }
        if let dlcIds = dlcIds {
            input["dlcIds"] = dlcIds
        }

        do {
            let response: UpdateGameVersionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id, "input": input]
            )
            if response.updateGameVersion.success {
                await fetchVersions(gameId: gameId)
                DispatchQueue.main.async {
                    self.successMessage = "Version updated successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update version"
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

    func deleteVersion(id: String, gameId: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation DeleteGameVersion($id: ID!) {
            deleteGameVersion(id: $id) {
                success
                deletedId
            }
        }
        """

        do {
            let response: DeleteGameVersionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            if response.deleteGameVersion.success {
                DispatchQueue.main.async {
                    self.versions.removeAll { $0.id == id }
                    self.successMessage = "Version deleted successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete version"
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

    func setDefaultVersion(id: String, gameId: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation SetDefaultVersion($id: ID!) {
            setDefaultVersion(id: $id) {
                success
                gameVersion {
                    id
                    name
                    isDefault
                }
            }
        }
        """

        do {
            let response: SetDefaultVersionResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            if response.setDefaultVersion.success {
                await fetchVersions(gameId: gameId)
                DispatchQueue.main.async {
                    self.successMessage = "Default version updated"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to set default version"
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

    func bulkDeleteVersions(ids: [String], gameId: String) async -> Int {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation BulkDeleteGameVersions($ids: [ID!]!) {
            bulkDeleteGameVersions(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        do {
            let response: BulkDeleteGameVersionsResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["ids": ids]
            )
            if response.bulkDeleteGameVersions.success {
                DispatchQueue.main.async {
                    self.versions.removeAll { ids.contains($0.id) }
                    self.successMessage = "Deleted \(response.bulkDeleteGameVersions.deletedCount) version(s)"
                }
                return response.bulkDeleteGameVersions.deletedCount
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete versions"
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
