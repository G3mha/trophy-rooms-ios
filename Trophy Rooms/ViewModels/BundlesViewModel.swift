import Foundation
import Combine

class BundlesViewModel: ObservableObject {
    @Published var bundles: [BundleListItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""

    var filteredBundles: [BundleListItem] {
        if searchText.isEmpty {
            return bundles
        }
        return bundles.filter { bundle in
            bundle.name.localizedCaseInsensitiveContains(searchText) ||
            (bundle.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    func fetchBundles(type: BundleType? = nil) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let typeParam = type != nil ? "($type: BundleType)" : ""
        let typeArg = type != nil ? "(type: $type)" : ""

        let query = """
        query GetBundles\(typeParam) {
            bundles\(typeArg) {
                id
                name
                slug
                type
                description
                coverUrl
                gameCount
                dlcCount
            }
        }
        """

        var variables: [String: Any] = [:]
        if let type = type {
            variables["type"] = type.rawValue
        }

        do {
            let response: BundlesListResponse = try await NetworkService.shared.fetch(
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
}
