import Foundation

struct AdminDLCFormController {
    let viewModel: AdminDLCsViewModel
    let gameFamilyId: String
    let dlc: DLC?

    var isEditing: Bool {
        dlc != nil
    }

    var navigationTitle: String {
        isEditing ? "Edit DLC" : "New DLC"
    }

    var saveButtonTitle: String {
        isEditing ? "Save" : "Create"
    }

    func save(draft: AdminDLCFormDraft) async -> Bool {
        let platformIds = Array(draft.selectedPlatformIds)

        if let dlc {
            return await viewModel.updateDLC(
                id: dlc.id,
                gameFamilyId: gameFamilyId,
                name: draft.normalizedName,
                slug: draft.normalizedSlug,
                type: draft.type,
                description: draft.normalizedDescription,
                coverUrl: draft.normalizedCoverUrl,
                price: draft.normalizedPrice,
                platformIds: platformIds
            )
        }

        return await viewModel.createDLC(
            gameFamilyId: gameFamilyId,
            name: draft.normalizedName,
            slug: draft.normalizedSlug,
            type: draft.type,
            description: draft.normalizedDescription,
            coverUrl: draft.normalizedCoverUrl,
            price: draft.normalizedPrice,
            platformIds: platformIds
        )
    }
}
