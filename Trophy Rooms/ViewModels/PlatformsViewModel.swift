import Foundation
import Combine

class PlatformsViewModel: ObservableObject {
    @Published var platforms: [Platform] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    static let shared = PlatformsViewModel()

    func fetchPlatforms() async {
        // Don't refetch if we already have platforms
        if !platforms.isEmpty { return }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetPlatforms {
            platforms {
                id
                name
                slug
            }
        }
        """

        do {
            let response: PlatformsResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.platforms = response.platforms
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func platform(for id: String?) -> Platform? {
        guard let id = id else { return nil }
        return platforms.first { $0.id == id }
    }
}
