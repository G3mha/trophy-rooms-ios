import Foundation

extension AdminAchievementsViewModel {
    func createAchievement(
        title: String,
        description: String?,
        iconUrl: String?,
        points: Int,
        tier: AchievementTier?,
        achievementSetId: String
    ) async -> Bool {
        await performAchievementMutation(fallback: false) {
            let response = try await api.createAchievement(
                title: title,
                description: description,
                iconUrl: iconUrl,
                points: points,
                tier: tier,
                achievementSetId: achievementSetId
            )
            if response.createAchievement.success {
                await fetchAchievements(setId: achievementSetId)
                setSuccessMessage("Achievement created successfully")
                return true
            }

            setErrorMessage("Failed to create achievement")
            return false
        }
    }

    func updateAchievement(
        id: String,
        title: String,
        description: String?,
        iconUrl: String?,
        points: Int,
        tier: AchievementTier?
    ) async -> Bool {
        await performAchievementMutation(fallback: false) {
            let response = try await api.updateAchievement(
                id: id,
                title: title,
                description: description,
                iconUrl: iconUrl,
                points: points,
                tier: tier
            )
            if response.updateAchievement.success {
                if !selectedSetId.isEmpty {
                    await fetchAchievements(setId: selectedSetId)
                }
                setSuccessMessage("Achievement updated successfully")
                return true
            }

            setErrorMessage("Failed to update achievement")
            return false
        }
    }

    func deleteAchievement(id: String) async -> Bool {
        await performAchievementMutation(fallback: false) {
            let response = try await api.deleteAchievement(id: id)
            if response.deleteAchievement.success {
                DispatchQueue.main.async {
                    self.achievements.removeAll { $0.id == id }
                    self.successMessage = "Achievement deleted successfully"
                }
                return true
            }

            setErrorMessage("Failed to delete achievement")
            return false
        }
    }

    func bulkDeleteAchievements(ids: [String]) async -> Int {
        await performAchievementMutation(fallback: 0) {
            let response = try await api.bulkDeleteAchievements(ids: ids)
            if response.bulkDeleteAchievements.success {
                DispatchQueue.main.async {
                    self.achievements.removeAll { ids.contains($0.id) }
                    self.successMessage = "Deleted \(response.bulkDeleteAchievements.deletedCount) achievement(s)"
                }
                return response.bulkDeleteAchievements.deletedCount
            }

            setErrorMessage("Failed to delete achievements")
            return 0
        }
    }
}
