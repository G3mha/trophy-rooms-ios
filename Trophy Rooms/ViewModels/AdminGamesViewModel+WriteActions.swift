import Foundation

extension AdminGamesViewModel {
    func importGameFamilyFromIGDBUrl(url: String) async -> Bool {
        await performMutation(fallback: false) {
            let response = try await api.importGameFamilyFromIGDBUrl(url: url)
            if response.importGameFamilyFromIGDBUrl.success {
                await fetchGames(page: 1)
                setSuccessMessage("Game imported successfully")
                return true
            }

            setErrorMessage(response.importGameFamilyFromIGDBUrl.error?.message ?? "Failed to import game")
            return false
        }
    }

    func createGameFamily(
        title: String,
        description: String?,
        coverUrl: String?,
        platformIds: [String],
        type: GameType = .BASE_GAME,
        baseGameFamilyIds: [String]? = nil
    ) async -> Bool {
        await performMutation(fallback: false) {
            let response = try await api.createGameFamily(
                title: title,
                description: description,
                coverUrl: coverUrl,
                platformIds: platformIds,
                type: type,
                baseGameFamilyIds: baseGameFamilyIds
            )
            if response.createGameFamily.success {
                await fetchGames(page: 1)
                setSuccessMessage("Game created successfully")
                return true
            }

            setErrorMessage(response.createGameFamily.error?.message ?? "Failed to create game")
            return false
        }
    }

    func createGame(
        title: String,
        description: String?,
        coverUrl: String?,
        platformId: String,
        type: GameType = .BASE_GAME,
        baseGameFamilyIds: [String]? = nil
    ) async -> Bool {
        await performMutation(fallback: false) {
            let response = try await api.createGame(
                title: title,
                description: description,
                coverUrl: coverUrl,
                platformId: platformId,
                type: type,
                baseGameFamilyIds: baseGameFamilyIds
            )
            if response.createGame.success {
                await fetchGames(page: 1)
                setSuccessMessage("Game created successfully")
                return true
            }

            setErrorMessage(response.createGame.error?.message ?? "Failed to create game")
            return false
        }
    }

    func addPlatformToGameFamily(gameFamilyId: String, platformId: String) async -> Bool {
        await performMutation(fallback: false) {
            let response = try await api.addPlatformToGameFamily(gameFamilyId: gameFamilyId, platformId: platformId)
            if response.addPlatformToGameFamily.success {
                await fetchGames(page: currentPage)
                setSuccessMessage("Platform added successfully")
                return true
            }

            setErrorMessage(response.addPlatformToGameFamily.error?.message ?? "Failed to add platform")
            return false
        }
    }

    func updateGame(
        id: String,
        title: String,
        description: String?,
        coverUrl: String?,
        platformId: String,
        type: GameType = .BASE_GAME,
        baseGameFamilyIds: [String]? = nil
    ) async -> Bool {
        await performMutation(fallback: false) {
            let response = try await api.updateGame(
                id: id,
                title: title,
                description: description,
                coverUrl: coverUrl,
                platformId: platformId,
                type: type,
                baseGameFamilyIds: baseGameFamilyIds
            )
            if response.updateGame.success {
                await fetchGames(page: currentPage)
                setSuccessMessage("Game updated successfully")
                return true
            }

            setErrorMessage(response.updateGame.error?.message ?? "Failed to update game")
            return false
        }
    }

    func cloneGameToPlatform(
        gameId: String,
        targetPlatformId: String,
        copyAchievementSets: Bool
    ) async -> Bool {
        await performMutation(fallback: false) {
            let response = try await api.cloneGameToPlatform(
                gameId: gameId,
                targetPlatformId: targetPlatformId,
                copyAchievementSets: copyAchievementSets
            )
            if response.cloneGameToPlatform.success {
                await fetchGames(page: 1)
                setSuccessMessage("Game cloned successfully")
                return true
            }

            setErrorMessage(response.cloneGameToPlatform.error?.message ?? "Failed to clone game")
            return false
        }
    }
}
