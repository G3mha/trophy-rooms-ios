import Foundation

extension AdminGameVersionsViewModel {
    func createVersion(
        gameFamilyId: String,
        gameIds: [String],
        name: String,
        slug: String,
        description: String?,
        coverUrl: String?,
        dlcIds: [String]?,
        isDefault: Bool,
        digitalOnly: Bool
    ) async -> Bool {
        await performVersionMutation(fallback: false) {
            let response = try await api.createVersion(
                gameIds: gameIds,
                name: name,
                slug: slug,
                description: description,
                coverUrl: coverUrl,
                dlcIds: dlcIds,
                isDefault: isDefault,
                digitalOnly: digitalOnly
            )
            if response.createGameVersion.success {
                await fetchVersions(gameFamilyId: gameFamilyId)
                setSuccessMessage("Version created successfully")
                return true
            }

            setErrorMessage("Failed to create version")
            return false
        }
    }

    func updateVersion(
        id: String,
        gameFamilyId: String,
        gameIds: [String],
        name: String,
        slug: String,
        description: String?,
        coverUrl: String?,
        dlcIds: [String]?,
        digitalOnly: Bool
    ) async -> Bool {
        await performVersionMutation(fallback: false) {
            let response = try await api.updateVersion(
                id: id,
                gameIds: gameIds,
                name: name,
                slug: slug,
                description: description,
                coverUrl: coverUrl,
                dlcIds: dlcIds,
                digitalOnly: digitalOnly
            )
            if response.updateGameVersion.success {
                await fetchVersions(gameFamilyId: gameFamilyId)
                setSuccessMessage("Version updated successfully")
                return true
            }

            setErrorMessage("Failed to update version")
            return false
        }
    }

    func deleteVersion(id: String, gameFamilyId: String) async -> Bool {
        await performVersionMutation(fallback: false) {
            let response = try await api.deleteVersion(id: id)
            if response.deleteGameVersion.success {
                DispatchQueue.main.async {
                    self.versions.removeAll { $0.id == id }
                    self.successMessage = "Version deleted successfully"
                }
                return true
            }

            setErrorMessage("Failed to delete version")
            return false
        }
    }

    func setDefaultVersion(id: String, gameFamilyId: String) async -> Bool {
        await performVersionMutation(fallback: false) {
            let response = try await api.setDefaultVersion(id: id)
            if response.setDefaultVersion.success {
                await fetchVersions(gameFamilyId: gameFamilyId)
                setSuccessMessage("Default version updated")
                return true
            }

            setErrorMessage("Failed to set default version")
            return false
        }
    }

    func bulkDeleteVersions(ids: [String], gameFamilyId: String) async -> Int {
        await performVersionMutation(fallback: 0) {
            let response = try await api.bulkDeleteVersions(ids: ids)
            if response.bulkDeleteGameVersions.success {
                DispatchQueue.main.async {
                    self.versions.removeAll { ids.contains($0.id) }
                    self.successMessage = "Deleted \(response.bulkDeleteGameVersions.deletedCount) version(s)"
                }
                return response.bulkDeleteGameVersions.deletedCount
            }

            setErrorMessage("Failed to delete versions")
            return 0
        }
    }
}
