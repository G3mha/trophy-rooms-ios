import Foundation
import Combine

class GlobalSearchViewModel: ObservableObject {
    @Published var results: GlobalSearchResults?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var searchTask: Task<Void, Never>?

    var items: [GlobalSearchItem] {
        results?.items ?? []
    }

    var gameCount: Int {
        results?.gameCount ?? 0
    }

    var bundleCount: Int {
        results?.bundleCount ?? 0
    }

    var dlcCount: Int {
        results?.dlcCount ?? 0
    }

    var hasResults: Bool {
        results?.totalCount ?? 0 > 0
    }

    func search(query: String) async {
        // Cancel previous search
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)

        // Clear results if query is too short
        if trimmedQuery.count < 2 {
            DispatchQueue.main.async {
                self.results = nil
                self.isLoading = false
            }
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let graphqlQuery = """
        query GlobalSearch($query: String!, $limit: Int) {
            globalSearch(query: $query, limit: $limit) {
                items {
                    id
                    type
                    title
                    coverUrl
                    subtitle
                }
                gameCount
                bundleCount
                dlcCount
                totalCount
            }
        }
        """

        do {
            let response: GlobalSearchResponse = try await NetworkService.shared.fetch(
                query: graphqlQuery,
                variables: ["query": trimmedQuery, "limit": 30]
            )
            DispatchQueue.main.async {
                self.results = response.globalSearch
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func clearResults() {
        searchTask?.cancel()
        results = nil
        isLoading = false
        errorMessage = nil
    }
}
