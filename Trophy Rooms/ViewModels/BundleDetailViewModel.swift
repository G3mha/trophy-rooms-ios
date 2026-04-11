import Foundation
import Combine

class BundleDetailViewModel: ObservableObject {
    @Published var bundle: AppBundle?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOwnershipLoading = false

    func fetchBundle(id: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

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
            DispatchQueue.main.async {
                self.bundle = response.bundle
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func addOwnership(platformId: String?) async {
        guard let bundleId = bundle?.id else { return }

        DispatchQueue.main.async {
            self.isOwnershipLoading = true
        }

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
                await fetchBundle(id: bundleId)
            }

            DispatchQueue.main.async {
                self.isOwnershipLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isOwnershipLoading = false
            }
        }
    }

    func removeOwnership(platformId: String?) async {
        guard let bundleId = bundle?.id else { return }

        DispatchQueue.main.async {
            self.isOwnershipLoading = true
        }

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
                await fetchBundle(id: bundleId)
            }

            DispatchQueue.main.async {
                self.isOwnershipLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isOwnershipLoading = false
            }
        }
    }

    // Legacy method for backwards compatibility
    func toggleOwnership() async {
        guard let bundleId = bundle?.id else { return }
        let isCurrentlyOwned = bundle?.isOwned ?? false

        if isCurrentlyOwned {
            await removeOwnership(platformId: nil)
        } else {
            await addOwnership(platformId: nil)
        }
    }
}
