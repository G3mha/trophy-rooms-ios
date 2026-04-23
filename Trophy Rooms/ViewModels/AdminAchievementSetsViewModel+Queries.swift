import Foundation

extension AdminAchievementSetsViewModel {
    func fetchAchievementSets() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let response = try await api.fetchAchievementSets()
            DispatchQueue.main.async {
                self.achievementSets = response.achievementSets
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func fetchGames() async {
        do {
            let response = try await api.fetchGames()
            DispatchQueue.main.async {
                self.games = response.games.edges.map { $0.node }
            }
        } catch {
            setErrorMessage(error.localizedDescription)
        }
    }

    func fetchVersions(gameFamilyId: String) async {
        do {
            let response = try await api.fetchVersions(gameFamilyId: gameFamilyId)
            DispatchQueue.main.async {
                self.versions = response.gameVersions
            }
        } catch {
            DispatchQueue.main.async {
                self.versions = []
            }
        }
    }

    func fetchDlcs(gameFamilyId: String) async {
        do {
            let response = try await api.fetchDlcs(gameFamilyId: gameFamilyId)
            DispatchQueue.main.async {
                self.dlcs = response.dlcs
            }
        } catch {
            DispatchQueue.main.async {
                self.dlcs = []
            }
        }
    }
}
