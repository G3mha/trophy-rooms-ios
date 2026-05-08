import Foundation

extension AdminBundlesViewModel {
    func createBundle(
        name: String,
        slug: String,
        type: BundleType,
        description: String?,
        coverUrl: String?,
        price: Double?,
        platformIds: [String]
    ) async -> Bool {
        await performBundleMutation(fallback: false) {
            let response = try await api.createBundle(
                name: name,
                slug: slug,
                type: type,
                description: description,
                coverUrl: coverUrl,
                price: price,
                platformIds: platformIds
            )
            if response.createBundle.success {
                await fetchBundles()
                setSuccessMessage("Bundle created successfully")
                return true
            }

            setErrorMessage("Failed to create bundle")
            return false
        }
    }

    func updateBundle(
        id: String,
        name: String,
        slug: String,
        type: BundleType,
        description: String?,
        coverUrl: String?,
        price: Double?,
        platformIds: [String]
    ) async -> Bool {
        await performBundleMutation(fallback: false) {
            let response = try await api.updateBundle(
                id: id,
                name: name,
                slug: slug,
                type: type,
                description: description,
                coverUrl: coverUrl,
                price: price,
                platformIds: platformIds
            )
            if response.updateBundle.success {
                await fetchBundles()
                setSuccessMessage("Bundle updated successfully")
                return true
            }

            setErrorMessage("Failed to update bundle")
            return false
        }
    }
}
