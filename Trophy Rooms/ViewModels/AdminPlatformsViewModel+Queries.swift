import Foundation

extension AdminPlatformsViewModel {
    func fetchPlatforms() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let response = try await api.fetchPlatforms()
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
}
