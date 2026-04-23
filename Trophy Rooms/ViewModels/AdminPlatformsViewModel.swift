import Foundation
import Combine

class AdminPlatformsViewModel: ObservableObject {
    let api: AdminPlatformsAPI

    @Published var platforms: [AdminPlatform] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    init(api: AdminPlatformsAPI = .shared) {
        self.api = api
    }
}
