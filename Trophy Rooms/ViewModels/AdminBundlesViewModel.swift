import Foundation
import Combine

class AdminBundlesViewModel: ObservableObject {
    @Published var bundles: [AppBundle] = []
    @Published var availableGames: [GamePickerItem] = []
    @Published var availableDLCs: [DLCPickerItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    func fetchBundles(type: BundleType? = nil) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetBundles($type: BundleType) {
            bundles(type: $type) {
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
                }
                dlcs {
                    id
                    name
                    game {
                        id
                        title
                    }
                }
            }
        }
        """

        var variables: [String: Any] = [:]
        if let type = type {
            variables["type"] = type.rawValue
        }

        do {
            let response: BundlesResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: variables
            )
            DispatchQueue.main.async {
                self.bundles = response.bundles
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func createBundle(
        name: String,
        slug: String,
        type: BundleType,
        description: String?,
        coverUrl: String?,
        price: Double?
    ) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation CreateBundle($input: CreateBundleInput!) {
            createBundle(input: $input) {
                success
                bundle {
                    id
                    name
                    slug
                    type
                    description
                    coverUrl
                    price
                    gameCount
                    dlcCount
                }
            }
        }
        """

        var input: [String: Any] = [
            "name": name,
            "slug": slug,
            "type": type.rawValue
        ]

        if let description = description, !description.isEmpty {
            input["description"] = description
        }
        if let coverUrl = coverUrl, !coverUrl.isEmpty {
            input["coverUrl"] = coverUrl
        }
        if let price = price {
            input["price"] = price
        }

        do {
            let response: CreateBundleResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["input": input]
            )
            if response.createBundle.success {
                await fetchBundles()
                DispatchQueue.main.async {
                    self.successMessage = "Bundle created successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create bundle"
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
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
        price: Double?
    ) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation UpdateBundle($id: ID!, $input: UpdateBundleInput!) {
            updateBundle(id: $id, input: $input) {
                success
                bundle {
                    id
                    name
                    slug
                    type
                    description
                    coverUrl
                    price
                    gameCount
                    dlcCount
                }
            }
        }
        """

        var input: [String: Any] = [
            "name": name,
            "slug": slug,
            "type": type.rawValue
        ]

        if let description = description {
            input["description"] = description
        }
        if let coverUrl = coverUrl {
            input["coverUrl"] = coverUrl
        }
        if let price = price {
            input["price"] = price
        }

        do {
            let response: UpdateBundleResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id, "input": input]
            )
            if response.updateBundle.success {
                await fetchBundles()
                DispatchQueue.main.async {
                    self.successMessage = "Bundle updated successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update bundle"
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func deleteBundle(id: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation DeleteBundle($id: ID!) {
            deleteBundle(id: $id) {
                success
                deletedId
            }
        }
        """

        do {
            let response: DeleteBundleResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            if response.deleteBundle.success {
                DispatchQueue.main.async {
                    self.bundles.removeAll { $0.id == id }
                    self.successMessage = "Bundle deleted successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete bundle"
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func bulkDeleteBundles(ids: [String]) async -> Int {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation BulkDeleteBundles($ids: [ID!]!) {
            bulkDeleteBundles(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        do {
            let response: BulkDeleteBundlesResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["ids": ids]
            )
            if response.bulkDeleteBundles.success {
                DispatchQueue.main.async {
                    self.bundles.removeAll { ids.contains($0.id) }
                    self.successMessage = "Deleted \(response.bulkDeleteBundles.deletedCount) bundle(s)"
                }
                return response.bulkDeleteBundles.deletedCount
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete bundles"
                }
                return 0
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return 0
        }
    }

    // MARK: - Bundle Contents Management

    func fetchAvailableGames() async {
        let query = """
        query GetAllGames {
            gamesPage(pageSize: 100) {
                items {
                    id
                    title
                    coverUrl
                    platform { id name slug }
                }
            }
        }
        """

        do {
            let response: GamesPickerResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.availableGames = response.gamesPage.items
            }
        } catch {
            print("Error fetching games: \(error)")
        }
    }

    func fetchAvailableDLCs() async {
        let query = """
        query GetAllDLCs {
            allDlcs {
                id
                name
                type
                coverUrl
                game { id title }
            }
        }
        """

        do {
            let response: AllDLCsResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.availableDLCs = response.allDlcs
            }
        } catch {
            print("Error fetching DLCs: \(error)")
        }
    }

    func addGameToBundle(gameId: String, bundleId: String) async -> Bool {
        let mutation = """
        mutation AddGameToBundle($gameId: ID!, $bundleId: ID!) {
            addGameToBundle(gameId: $gameId, bundleId: $bundleId) {
                success
            }
        }
        """

        do {
            let response: AddGameToBundleResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["gameId": gameId, "bundleId": bundleId]
            )
            if response.addGameToBundle.success {
                await fetchBundles()
                return true
            }
            return false
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func removeGameFromBundle(gameId: String, bundleId: String) async -> Bool {
        let mutation = """
        mutation RemoveGameFromBundle($gameId: ID!, $bundleId: ID!) {
            removeGameFromBundle(gameId: $gameId, bundleId: $bundleId) {
                success
            }
        }
        """

        do {
            let response: RemoveGameFromBundleResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["gameId": gameId, "bundleId": bundleId]
            )
            if response.removeGameFromBundle.success {
                await fetchBundles()
                return true
            }
            return false
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func addDLCToBundle(dlcId: String, bundleId: String) async -> Bool {
        let mutation = """
        mutation AddDLCToBundle($dlcId: ID!, $bundleId: ID!) {
            addDLCToBundle(dlcId: $dlcId, bundleId: $bundleId) {
                success
            }
        }
        """

        do {
            let response: AddDLCToBundleResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["dlcId": dlcId, "bundleId": bundleId]
            )
            if response.addDLCToBundle.success {
                await fetchBundles()
                return true
            }
            return false
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func removeDLCFromBundle(dlcId: String, bundleId: String) async -> Bool {
        let mutation = """
        mutation RemoveDLCFromBundle($dlcId: ID!, $bundleId: ID!) {
            removeDLCFromBundle(dlcId: $dlcId, bundleId: $bundleId) {
                success
            }
        }
        """

        do {
            let response: RemoveDLCFromBundleResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["dlcId": dlcId, "bundleId": bundleId]
            )
            if response.removeDLCFromBundle.success {
                await fetchBundles()
                return true
            }
            return false
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
}
