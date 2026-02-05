import Foundation

class StatsViewModel: ObservableObject {
    @Published var stats: UserStats?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchStats() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetMyStats {
            myStats {
                totalTrophies
                totalAchievements
                totalGamesPlayed
            }
        }
        """

        do {
            let response: StatsResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.stats = response.myStats
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
