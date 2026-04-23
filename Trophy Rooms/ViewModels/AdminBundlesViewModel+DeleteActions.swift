import Foundation

extension AdminBundlesViewModel {
    func deleteBundle(id: String) async -> Bool {
        await performBundleMutation(fallback: false) {
            let response = try await api.deleteBundle(id: id)
            if response.deleteBundle.success {
                DispatchQueue.main.async {
                    self.bundles.removeAll { $0.id == id }
                    self.successMessage = "Bundle deleted successfully"
                }
                return true
            }

            setErrorMessage("Failed to delete bundle")
            return false
        }
    }

    func bulkDeleteBundles(ids: [String]) async -> Int {
        await performBundleMutation(fallback: 0) {
            let response = try await api.bulkDeleteBundles(ids: ids)
            if response.bulkDeleteBundles.success {
                DispatchQueue.main.async {
                    self.bundles.removeAll { ids.contains($0.id) }
                    self.successMessage = "Deleted \(response.bulkDeleteBundles.deletedCount) bundle(s)"
                }
                return response.bulkDeleteBundles.deletedCount
            }

            setErrorMessage("Failed to delete bundles")
            return 0
        }
    }
}
