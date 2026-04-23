import Foundation

extension AdminAchievementSetsViewModel {
    func createAchievementSet(
        title: String,
        type: AchievementSetType,
        visibility: AchievementSetVisibility,
        gameFamilyId: String,
        gameVersionId: String? = nil,
        dlcId: String? = nil
    ) async -> Bool {
        await performAchievementSetMutation(fallback: false) {
            let response = try await api.createAchievementSet(
                title: title,
                type: type,
                visibility: visibility,
                gameFamilyId: gameFamilyId,
                gameVersionId: gameVersionId,
                dlcId: dlcId
            )
            if response.createAchievementSet.success {
                await fetchAchievementSets()
                setSuccessMessage("Achievement set created successfully")
                return true
            }

            setErrorMessage("Failed to create achievement set")
            return false
        }
    }

    func updateAchievementSet(
        id: String,
        title: String,
        type: AchievementSetType,
        visibility: AchievementSetVisibility,
        gameFamilyId: String,
        gameVersionId: String? = nil,
        dlcId: String? = nil
    ) async -> Bool {
        await performAchievementSetMutation(fallback: false) {
            let response = try await api.updateAchievementSet(
                id: id,
                title: title,
                type: type,
                visibility: visibility,
                gameFamilyId: gameFamilyId,
                gameVersionId: gameVersionId,
                dlcId: dlcId
            )
            if response.updateAchievementSet.success {
                await fetchAchievementSets()
                setSuccessMessage("Achievement set updated successfully")
                return true
            }

            setErrorMessage("Failed to update achievement set")
            return false
        }
    }

    func deleteAchievementSet(id: String) async -> Bool {
        await performAchievementSetMutation(fallback: false) {
            let response = try await api.deleteAchievementSet(id: id)
            if response.deleteAchievementSet.success {
                DispatchQueue.main.async {
                    self.achievementSets.removeAll { $0.id == id }
                    self.successMessage = "Achievement set deleted successfully"
                }
                return true
            }

            setErrorMessage("Failed to delete achievement set")
            return false
        }
    }

    func bulkDeleteAchievementSets(ids: [String]) async -> Int {
        await performAchievementSetMutation(fallback: 0) {
            let response = try await api.bulkDeleteAchievementSets(ids: ids)
            if response.bulkDeleteAchievementSets.success {
                DispatchQueue.main.async {
                    self.achievementSets.removeAll { ids.contains($0.id) }
                    self.successMessage = "Deleted \(response.bulkDeleteAchievementSets.deletedCount) set(s)"
                }
                return response.bulkDeleteAchievementSets.deletedCount
            }

            setErrorMessage("Failed to delete achievement sets")
            return 0
        }
    }
}
