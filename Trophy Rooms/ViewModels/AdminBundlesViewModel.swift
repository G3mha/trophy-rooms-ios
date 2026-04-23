import Foundation
import Combine

class AdminBundlesViewModel: ObservableObject {
    let api: AdminBundlesAPI

    @Published var bundles: [AppBundle] = []
    @Published var availableDLCs: [DLCPickerItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    init(api: AdminBundlesAPI = .shared) {
        self.api = api
    }
}
