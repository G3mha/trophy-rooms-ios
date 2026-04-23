import Foundation

extension AdminBundlesViewModel {
    func fetchBundles(type: BundleType? = nil) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let response = try await api.fetchBundles(type: type)
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

    func fetchAvailableDLCs() async {
        do {
            let response = try await api.fetchAvailableDLCs()
            DispatchQueue.main.async {
                self.availableDLCs = response.allDlcs
            }
        } catch {
            print("Error fetching DLCs: \(error)")
        }
    }
}
