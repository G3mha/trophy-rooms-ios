import Foundation

extension AdminBundlesViewModel {
    func addGameFamilyToBundle(gameFamilyId: String, bundleId: String) async -> Bool {
        await performBundleMutation(fallback: false) {
            let response = try await api.addGameFamilyToBundle(gameFamilyId: gameFamilyId, bundleId: bundleId)
            if response.addGameFamilyToBundle.success {
                await fetchBundles()
                return true
            }
            return false
        }
    }

    func removeGameFamilyFromBundle(gameFamilyId: String, bundleId: String) async -> Bool {
        await performBundleMutation(fallback: false) {
            let response = try await api.removeGameFamilyFromBundle(gameFamilyId: gameFamilyId, bundleId: bundleId)
            if response.removeGameFamilyFromBundle.success {
                await fetchBundles()
                return true
            }
            return false
        }
    }

    func addDLCToBundle(dlcId: String, bundleId: String) async -> Bool {
        await performBundleMutation(fallback: false) {
            let response = try await api.addDLCToBundle(dlcId: dlcId, bundleId: bundleId)
            if response.addDLCToBundle.success {
                await fetchBundles()
                return true
            }
            return false
        }
    }

    func removeDLCFromBundle(dlcId: String, bundleId: String) async -> Bool {
        await performBundleMutation(fallback: false) {
            let response = try await api.removeDLCFromBundle(dlcId: dlcId, bundleId: bundleId)
            if response.removeDLCFromBundle.success {
                await fetchBundles()
                return true
            }
            return false
        }
    }
}
