import Foundation

struct AdminAchievementFormController {
    let viewModel: AdminAchievementsViewModel
    let achievement: AdminAchievement?

    var navigationTitle: String {
        achievement == nil ? "New Achievement" : "Edit Achievement"
    }

    var saveButtonTitle: String {
        achievement == nil ? "Create" : "Save"
    }

    func save(draft: AdminAchievementFormDraft) async -> Bool {
        if let achievement {
            return await viewModel.updateAchievement(
                id: achievement.id,
                title: draft.normalizedTitle,
                description: draft.normalizedDescription,
                iconUrl: draft.normalizedIconUrl,
                points: draft.points,
                tier: draft.selectedTier
            )
        }

        return await viewModel.createAchievement(
            title: draft.normalizedTitle,
            description: draft.normalizedDescription,
            iconUrl: draft.normalizedIconUrl,
            points: draft.points,
            tier: draft.selectedTier,
            achievementSetId: viewModel.selectedSetId
        )
    }
}
