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
                gameCount
                dlcCount
                games {
                    id
                    title
                    coverUrl
                    platform {
                        id
                        name
                        slug
                    }
                }
                dlcs {
                    id
                    name
                    slug
                    type
                    coverUrl
                    game {
                        id
                        title
                    }
                }
                isOwned
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

    func toggleOwnership() async {
        guard let bundleId = bundle?.id else { return }

        DispatchQueue.main.async {
            self.isOwnershipLoading = true
        }

        let isCurrentlyOwned = bundle?.isOwned ?? false
        let mutationName = isCurrentlyOwned ? "RemoveBundleFromOwned" : "AddBundleToOwned"
        let mutationField = isCurrentlyOwned ? "removeBundleFromOwned" : "addBundleToOwned"

        let mutation = """
        mutation \(mutationName)($bundleId: ID!) {
            \(mutationField)(bundleId: $bundleId) {
                success
            }
        }
        """

        do {
            let response: BundleOwnershipMutationResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["bundleId": bundleId]
            )

            let success = isCurrentlyOwned
                ? response.removeBundleFromOwned?.success ?? false
                : response.addBundleToOwned?.success ?? false

            if success {
                // Refetch bundle to get updated ownership state
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
}
