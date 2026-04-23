import Foundation

extension AdminPlatformsViewModel {
    func createPlatformRelease(platformId: String, region: String, releaseDate: Date) async -> Bool {
        await performPlatformMutation(fallback: false) {
            let response = try await api.createPlatformRelease(
                platformId: platformId,
                region: region,
                releaseDate: releaseDate
            )
            if response.createPlatformRelease.success {
                await fetchPlatforms()
                setSuccessMessage("Release date added successfully")
                return true
            }

            setErrorMessage("Failed to add release date")
            return false
        }
    }

    func updatePlatformRelease(id: String, region: String? = nil, releaseDate: Date? = nil) async -> Bool {
        await performPlatformMutation(fallback: false) {
            let response = try await api.updatePlatformRelease(
                id: id,
                region: region,
                releaseDate: releaseDate
            )
            if response.updatePlatformRelease.success {
                await fetchPlatforms()
                setSuccessMessage("Release date updated successfully")
                return true
            }

            setErrorMessage("Failed to update release date")
            return false
        }
    }

    func deletePlatformRelease(id: String) async -> Bool {
        await performPlatformMutation(fallback: false) {
            let response = try await api.deletePlatformRelease(id: id)
            if response.deletePlatformRelease.success {
                await fetchPlatforms()
                setSuccessMessage("Release date deleted successfully")
                return true
            }

            setErrorMessage("Failed to delete release date")
            return false
        }
    }
}
