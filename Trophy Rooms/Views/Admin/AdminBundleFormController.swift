import Foundation

struct AdminBundleFormController {
    let viewModel: AdminBundlesViewModel
    let bundle: AppBundle?

    var isEditing: Bool {
        bundle != nil
    }

    var navigationTitle: String {
        isEditing ? "Edit Bundle" : "New Bundle"
    }

    var saveButtonTitle: String {
        isEditing ? "Save" : "Create"
    }

    func save(draft: AdminBundleFormDraft) async -> Bool {
        if let bundle {
            return await viewModel.updateBundle(
                id: bundle.id,
                name: draft.normalizedName,
                slug: draft.normalizedSlug,
                type: draft.type,
                description: draft.normalizedDescription,
                coverUrl: draft.normalizedCoverUrl,
                price: draft.normalizedPrice,
                platformIds: Array(draft.selectedPlatformIds)
            )
        }

        return await viewModel.createBundle(
            name: draft.normalizedName,
            slug: draft.normalizedSlug,
            type: draft.type,
            description: draft.normalizedDescription,
            coverUrl: draft.normalizedCoverUrl,
            price: draft.normalizedPrice,
            platformIds: Array(draft.selectedPlatformIds)
        )
    }
}
