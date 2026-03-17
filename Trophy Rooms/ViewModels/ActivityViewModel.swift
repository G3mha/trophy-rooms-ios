import Foundation
import Combine

enum ActivityFilter: String, CaseIterable, Identifiable {
    case all
    case achievements
    case trophies

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .achievements: return "Achievements"
        case .trophies: return "Trophies"
        }
    }

    var graphqlValue: String? {
        switch self {
        case .all: return nil
        case .achievements: return "ACHIEVEMENT"
        case .trophies: return "TROPHY"
        }
    }
}

class ActivityViewModel: ObservableObject {
    @Published var activities: [ActivityEntry] = []
    @Published var selectedFilter: ActivityFilter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchActivity() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetActivityFeed($limit: Int, $type: String) {
            activityFeed(limit: $limit, type: $type) {
                id
                type
                userId
                userName
                userEmail
                achievementId
                achievementTitle
                achievementTier
                achievementPoints
                gameId
                gameTitle
                platformName
                earnedAt
            }
        }
        """

        var variables: [String: Any] = ["limit": 50]
        if let typeFilter = selectedFilter.graphqlValue {
            variables["type"] = typeFilter
        }

        do {
            let response: ActivityResponse = try await NetworkService.shared.fetch(query: query, variables: variables)
            DispatchQueue.main.async {
                self.activities = response.activityFeed
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
