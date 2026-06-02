import Foundation
import Combine

@MainActor
class BundleDetailViewModel: ObservableObject {
    @Published var bundle: AppBundle?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOwnershipLoading = false

    func fetchBundle(id: String, forceRefresh: Bool = false) async {
        // Load from cache immediately (no loading state)
        if !forceRefresh, let cached: BundleResponse = await CacheManager.shared.get(.bundle(id: id)) {
            bundle = cached.bundle
        }

        // Show loading only if no cached data
        if bundle == nil {
            isLoading = true
        }
        errorMessage = nil

        let query = """
        query GetBundle($id: ID!) {
            bundle(id: $id) {
                id
                name
                slug
                type
                description
                coverUrl
                releaseDate
                price
                platforms {
                    id
                    name
                    slug
                }
                platformCount
                gameFamilyCount
                dlcCount
                gameFamilies {
                    id
                    title
                    coverUrl
                }
                dlcs {
                    id
                    name
                    slug
                    type
                    coverUrl
                    gameFamily {
                        id
                        title
                        coverUrl
                    }
                }
                isOwned
                ownedPlatforms {
                    id
                    name
                    slug
                }
            }
        }
        """

        do {
            let response: BundleResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["id": id]
            )
            await CacheManager.shared.set(.bundle(id: id), value: response)
            bundle = response.bundle
        } catch {
            // Only show error if no cached data
            if bundle == nil {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func addOwnership(platformId: String?) async {
        guard let bundleId = bundle?.id else { return }

        isOwnershipLoading = true

        let mutation = """
        mutation AddBundleToOwned($bundleId: ID!, $platformId: ID) {
            addBundleToOwned(bundleId: $bundleId, platformId: $platformId) {
                success
            }
        }
        """

        var variables: [String: Any] = ["bundleId": bundleId]
        if let platformId = platformId {
            variables["platformId"] = platformId
        }

        do {
            let response: BundleOwnershipMutationResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )

            if response.addBundleToOwned?.success == true {
                await CacheInvalidation.forBundleOwnershipChange()
                await CacheInvalidation.forBundle(id: bundleId)
                await fetchBundle(id: bundleId, forceRefresh: true)
            }

            isOwnershipLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isOwnershipLoading = false
        }
    }

    func removeOwnership(platformId: String?) async {
        guard let bundleId = bundle?.id else { return }

        isOwnershipLoading = true

        let mutation = """
        mutation RemoveBundleFromOwned($bundleId: ID!, $platformId: ID) {
            removeBundleFromOwned(bundleId: $bundleId, platformId: $platformId) {
                success
            }
        }
        """

        var variables: [String: Any] = ["bundleId": bundleId]
        if let platformId = platformId {
            variables["platformId"] = platformId
        }

        do {
            let response: BundleOwnershipMutationResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )

            if response.removeBundleFromOwned?.success == true {
                await CacheInvalidation.forBundleOwnershipChange()
                await CacheInvalidation.forBundle(id: bundleId)
                await fetchBundle(id: bundleId, forceRefresh: true)
            }

            isOwnershipLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isOwnershipLoading = false
        }
    }

    // Legacy method for backwards compatibility
    func toggleOwnership() async {
        guard bundle?.id != nil else { return }
        let isCurrentlyOwned = bundle?.isOwned ?? false

        if isCurrentlyOwned {
            await removeOwnership(platformId: nil)
        } else {
            await addOwnership(platformId: nil)
        }
    }
}
