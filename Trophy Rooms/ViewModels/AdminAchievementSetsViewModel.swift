import Foundation
import Combine

class AdminAchievementSetsViewModel: ObservableObject {
    let api: AdminAchievementSetsAPI

    @Published var achievementSets: [AdminAchievementSet] = []
    @Published var games: [AdminGame] = []
    @Published var versions: [GameVersion] = []
    @Published var dlcs: [DLC] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var searchText: String = ""

    var filteredSets: [AdminAchievementSet] {
        if searchText.isEmpty {
            return achievementSets
        }
        return achievementSets.filter { set in
            set.title.localizedCaseInsensitiveContains(searchText) ||
            (set.gameFamily?.title.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    init(api: AdminAchievementSetsAPI = .shared) {
        self.api = api
    }
}
