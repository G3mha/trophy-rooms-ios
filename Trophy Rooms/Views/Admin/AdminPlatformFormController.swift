import Foundation

struct AdminPlatformFormController {
    let viewModel: AdminPlatformsViewModel
    let platform: AdminPlatform?

    var isEditing: Bool {
        platform != nil
    }

    func save(draft: AdminPlatformFormDraft) async -> Bool {
        if let platform {
            return await viewModel.updatePlatform(
                id: platform.id,
                name: draft.normalizedName,
                slug: draft.normalizedSlug,
                description: draft.normalizedDescription,
                consolePictureUrl: draft.normalizedConsolePictureUrl,
                promotionalPictures: draft.normalizedPromotionalPictures
            )
        }

        return await viewModel.createPlatform(
            name: draft.normalizedName,
            slug: draft.normalizedSlug,
            description: draft.normalizedDescription,
            consolePictureUrl: draft.normalizedConsolePictureUrl,
            promotionalPictures: draft.normalizedPromotionalPictures
        )
    }
}
