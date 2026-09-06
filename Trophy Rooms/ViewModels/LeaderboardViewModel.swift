import Foundation
import Combine

enum LeaderboardType: String, CaseIterable, Identifiable {
    case trophies
    case achievements
    case points
    case games
    case fastest

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trophies: return "Trophies"
        case .achievements: return "Achievements"
        case .points: return "Points"
        case .games: return "Games"
        case .fastest: return "Fastest"
        }
    }

    var icon: String {
        switch self {
        case .trophies: return "trophy"
        case .achievements: return "star"
        case .points: return "number"
        case .games: return "gamecontroller"
        case .fastest: return "bolt"
        }
    }
}

class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var fastestEntries: [FastestCompletionEntry] = []
    @Published var selectedType: LeaderboardType = .trophies
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchLeaderboard() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            switch selectedType {
            case .trophies:
                let response: LeaderboardResponse = try await fetchLeaderboardByTrophies()
                DispatchQueue.main.async {
                    self.entries = response.leaderboardByTrophies ?? []
                    self.isLoading = false
                }
            case .achievements:
                let response: LeaderboardResponse = try await fetchLeaderboardByAchievements()
                DispatchQueue.main.async {
                    self.entries = response.leaderboardByAchievements ?? []
                    self.isLoading = false
                }
            case .points:
                let response: LeaderboardResponse = try await fetchLeaderboardByPoints()
                DispatchQueue.main.async {
                    self.entries = response.leaderboardByPoints ?? []
                    self.isLoading = false
                }
            case .games:
                let response: LeaderboardResponse = try await fetchLeaderboardByGames()
                DispatchQueue.main.async {
                    self.entries = response.leaderboardByGamesPlayed ?? []
                    self.isLoading = false
                }
            case .fastest:
                let response: FastestCompletionsResponse = try await fetchFastestCompletions()
                DispatchQueue.main.async {
                    self.fastestEntries = response.fastestCompletions
                    self.isLoading = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func fetchLeaderboardByTrophies() async throws -> LeaderboardResponse {
        let query = """
        query GetLeaderboardByTrophies($limit: Int) {
            leaderboardByTrophies(limit: $limit) {
                rank
                userId
                userName
                value
                secondaryValue
            }
        }
        """
        return try await NetworkService.shared.fetch(query: query, variables: ["limit": 50])
    }

    private func fetchLeaderboardByAchievements() async throws -> LeaderboardResponse {
        let query = """
        query GetLeaderboardByAchievements($limit: Int) {
            leaderboardByAchievements(limit: $limit) {
                rank
                userId
                userName
                value
                secondaryValue
            }
        }
        """
        return try await NetworkService.shared.fetch(query: query, variables: ["limit": 50])
    }

    private func fetchLeaderboardByPoints() async throws -> LeaderboardResponse {
        let query = """
        query GetLeaderboardByPoints($limit: Int) {
            leaderboardByPoints(limit: $limit) {
                rank
                userId
                userName
                value
                secondaryValue
            }
        }
        """
        return try await NetworkService.shared.fetch(query: query, variables: ["limit": 50])
    }

    private func fetchLeaderboardByGames() async throws -> LeaderboardResponse {
        let query = """
        query GetLeaderboardByGames($limit: Int) {
            leaderboardByGamesPlayed(limit: $limit) {
                rank
                userId
                userName
                value
                secondaryValue
            }
        }
        """
        return try await NetworkService.shared.fetch(query: query, variables: ["limit": 50])
    }

    private func fetchFastestCompletions() async throws -> FastestCompletionsResponse {
        let query = """
        query GetFastestCompletions($limit: Int) {
            fastestCompletions(limit: $limit) {
                rank
                userId
                userName
                gameId
                gameTitle
                completionTimeHours
                completedAt
            }
        }
        """
        return try await NetworkService.shared.fetch(query: query, variables: ["limit": 50])
    }
}
