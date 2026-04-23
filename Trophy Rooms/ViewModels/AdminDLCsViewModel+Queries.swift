import Foundation

extension AdminDLCsViewModel {
    func fetchDLCs(gameFamilyId: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let response = try await api.fetchDLCs(gameFamilyId: gameFamilyId)
            DispatchQueue.main.async {
                self.dlcs = response.dlcs
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
