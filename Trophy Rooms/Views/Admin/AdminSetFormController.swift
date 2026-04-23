import Foundation

struct AdminSetFormController {
    let viewModel: AdminAchievementSetsViewModel
    let achievementSet: AdminAchievementSet?

    var navigationTitle: String {
        achievementSet == nil ? "New Set" : "Edit Set"
    }

    var saveButtonTitle: String {
        achievementSet == nil ? "Create" : "Save"
    }

    func save(draft: AdminSetFormDraft, gameFamilyId: String) async -> Bool {
        if let achievementSet {
            return await viewModel.updateAchievementSet(
                id: achievementSet.id,
                title: draft.normalizedTitle,
                type: draft.selectedType,
                visibility: draft.selectedVisibility,
                gameFamilyId: gameFamilyId,
                gameVersionId: draft.normalizedVersionId,
                dlcId: draft.normalizedDlcId
            )
        }

        return await viewModel.createAchievementSet(
            title: draft.normalizedTitle,
            type: draft.selectedType,
            visibility: draft.selectedVisibility,
            gameFamilyId: gameFamilyId,
            gameVersionId: draft.normalizedVersionId,
            dlcId: draft.normalizedDlcId
        )
    }
}
