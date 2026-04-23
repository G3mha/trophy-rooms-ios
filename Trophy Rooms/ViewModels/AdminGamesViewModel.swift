import Foundation
import Combine

class AdminGamesViewModel: ObservableObject {
    let api: AdminGamesAPI

    @Published var games: [AdminGameItem] = []
    @Published var platforms: [AdminPlatform] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var searchText: String = ""
    @Published var isGrouped: Bool = true

    @Published var currentPage: Int = 1
    @Published var totalCount: Int = 0
    @Published var totalPages: Int = 1
    @Published var pageSize: Int = 50

    /// Single game for editing (used by inline admin toolbar)
    @Published var gameToEdit: AdminGameItem?

    init(api: AdminGamesAPI = .shared) {
        self.api = api
    }
}
