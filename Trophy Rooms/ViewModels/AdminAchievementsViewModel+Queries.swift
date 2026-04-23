import Foundation

extension AdminAchievementsViewModel {
    func fetchAchievementSets() async {
        do {
            let response = try await api.fetchAchievementSets()
            DispatchQueue.main.async {
                self.achievementSets = response.achievementSets
            }
        } catch {
            setErrorMessage(error.localizedDescription)
        }
    }

    func fetchAchievements(setId: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.selectedSetId = setId
        }

        do {
            let response = try await api.fetchAchievements(setId: setId)
            DispatchQueue.main.async {
                if let set = response.achievementSet {
                    self.achievements = set.achievements
                    self.currentSetTitle = set.title
                } else {
                    self.achievements = []
                    self.currentSetTitle = ""
                }
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
