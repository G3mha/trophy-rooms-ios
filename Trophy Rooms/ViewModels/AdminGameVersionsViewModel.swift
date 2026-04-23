import Foundation
import Combine

class AdminGameVersionsViewModel: ObservableObject {
    let api: AdminGameVersionsAPI

    @Published var versions: [GameVersion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    init(api: AdminGameVersionsAPI = .shared) {
        self.api = api
    }
}
