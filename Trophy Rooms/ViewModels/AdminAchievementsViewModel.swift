import Foundation
import Combine

class AdminAchievementsViewModel: ObservableObject {
    let api: AdminAchievementsAPI

    @Published var achievements: [AdminAchievement] = []
    @Published var achievementSets: [AdminAchievementSet] = []
    @Published var selectedSetId: String = ""
    @Published var currentSetTitle: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published var csvPreviewData: [[String]] = []
    @Published var importResult: BulkCreateResult?

    init(api: AdminAchievementsAPI = .shared) {
        self.api = api
    }
}
