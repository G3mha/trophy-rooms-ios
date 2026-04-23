import Foundation

extension AdminGameVersionsViewModel {
    func fetchVersions(gameFamilyId: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let response = try await api.fetchVersions(gameFamilyId: gameFamilyId)
            DispatchQueue.main.async {
                self.versions = response.gameVersions
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
