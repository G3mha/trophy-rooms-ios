import Foundation

extension AdminPlatformsViewModel {
    func createPlatform(
        name: String,
        slug: String,
        description: String? = nil,
        consolePictureUrl: String? = nil,
        promotionalPictures: [String]? = nil
    ) async -> Bool {
        await performPlatformMutation(fallback: false) {
            let response = try await api.createPlatform(
                name: name,
                slug: slug,
                description: description,
                consolePictureUrl: consolePictureUrl,
                promotionalPictures: promotionalPictures
            )
            if response.createPlatform.success {
                await fetchPlatforms()
                setSuccessMessage("Platform created successfully")
                return true
            }

            setErrorMessage("Failed to create platform")
            return false
        }
    }

    func updatePlatform(
        id: String,
        name: String,
        slug: String,
        description: String? = nil,
        consolePictureUrl: String? = nil,
        promotionalPictures: [String]? = nil
    ) async -> Bool {
        await performPlatformMutation(fallback: false) {
            let response = try await api.updatePlatform(
                id: id,
                name: name,
                slug: slug,
                description: description,
                consolePictureUrl: consolePictureUrl,
                promotionalPictures: promotionalPictures
            )
            if response.updatePlatform.success {
                await fetchPlatforms()
                setSuccessMessage("Platform updated successfully")
                return true
            }

            setErrorMessage("Failed to update platform")
            return false
        }
    }

    func deletePlatform(id: String) async -> Bool {
        await performPlatformMutation(fallback: false) {
            let response = try await api.deletePlatform(id: id)
            if response.deletePlatform.success {
                DispatchQueue.main.async {
                    self.platforms.removeAll { $0.id == id }
                    self.successMessage = "Platform deleted successfully"
                }
                return true
            }

            setErrorMessage("Failed to delete platform")
            return false
        }
    }

    func bulkDeletePlatforms(ids: [String]) async -> Int {
        await performPlatformMutation(fallback: 0) {
            let response = try await api.bulkDeletePlatforms(ids: ids)
            if response.bulkDeletePlatforms.success {
                DispatchQueue.main.async {
                    self.platforms.removeAll { ids.contains($0.id) }
                    self.successMessage = "Deleted \(response.bulkDeletePlatforms.deletedCount) platform(s)"
                }
                return response.bulkDeletePlatforms.deletedCount
            }

            setErrorMessage("Failed to delete platforms")
            return 0
        }
    }
}
