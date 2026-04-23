import Foundation

extension AdminBundlesAPI {
    func addGameFamilyToBundle(gameFamilyId: String, bundleId: String) async throws -> AddGameFamilyToBundleResponse {
        let mutation = """
        mutation AddGameFamilyToBundle($gameFamilyId: ID!, $bundleId: ID!) {
            addGameFamilyToBundle(gameFamilyId: $gameFamilyId, bundleId: $bundleId) {
                success
            }
        }
        """

        return try await networkService.fetch(
            query: mutation,
            variables: ["gameFamilyId": gameFamilyId, "bundleId": bundleId]
        )
    }

    func removeGameFamilyFromBundle(gameFamilyId: String, bundleId: String) async throws -> RemoveGameFamilyFromBundleResponse {
        let mutation = """
        mutation RemoveGameFamilyFromBundle($gameFamilyId: ID!, $bundleId: ID!) {
            removeGameFamilyFromBundle(gameFamilyId: $gameFamilyId, bundleId: $bundleId) {
                success
            }
        }
        """

        return try await networkService.fetch(
            query: mutation,
            variables: ["gameFamilyId": gameFamilyId, "bundleId": bundleId]
        )
    }

    func addDLCToBundle(dlcId: String, bundleId: String) async throws -> AddDLCToBundleResponse {
        let mutation = """
        mutation AddDLCToBundle($dlcId: ID!, $bundleId: ID!) {
            addDLCToBundle(dlcId: $dlcId, bundleId: $bundleId) {
                success
            }
        }
        """

        return try await networkService.fetch(
            query: mutation,
            variables: ["dlcId": dlcId, "bundleId": bundleId]
        )
    }

    func removeDLCFromBundle(dlcId: String, bundleId: String) async throws -> RemoveDLCFromBundleResponse {
        let mutation = """
        mutation RemoveDLCFromBundle($dlcId: ID!, $bundleId: ID!) {
            removeDLCFromBundle(dlcId: $dlcId, bundleId: $bundleId) {
                success
            }
        }
        """

        return try await networkService.fetch(
            query: mutation,
            variables: ["dlcId": dlcId, "bundleId": bundleId]
        )
    }
}
