import Foundation

struct GameCloneController {
    let viewModel: AdminGamesViewModel
    let gameId: String
    let gameTitle: String
    let currentPlatformId: String?

    var availablePlatforms: [AdminPlatform] {
        viewModel.platforms.filter { $0.id != currentPlatformId }
    }

    func clone(draft: GameCloneDraft) async -> [CloneResult] {
        var results: [CloneResult] = []

        for platformId in draft.selectedPlatformIds {
            let platform = viewModel.platforms.first { $0.id == platformId }
            let platformName = platform?.name ?? "Unknown"
            let platformSlug = platform?.slug ?? ""
            let success = await viewModel.cloneGameToPlatform(
                gameId: gameId,
                targetPlatformId: platformId,
                copyAchievementSets: draft.copyAchievementSets
            )

            results.append(CloneResult(
                platformId: platformId,
                platformSlug: platformSlug,
                platformName: platformName,
                success: success,
                error: success ? nil : viewModel.errorMessage
            ))
        }

        return results
    }
}
