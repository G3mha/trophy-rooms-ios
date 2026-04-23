import Foundation
import Combine

class AdminDLCsViewModel: ObservableObject {
    let api: AdminDLCsAPI

    @Published var dlcs: [DLC] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    init(api: AdminDLCsAPI = .shared) {
        self.api = api
    }
}
