import Foundation

struct PlatformReleaseFormController {
    let viewModel: AdminPlatformsViewModel
    let platformId: String
    let release: PlatformRelease?

    var navigationTitle: String {
        release == nil ? "Add Release" : "Edit Release"
    }

    func save(draft: PlatformReleaseFormDraft) async -> Bool {
        if let release {
            return await viewModel.updatePlatformRelease(
                id: release.id,
                region: draft.region,
                releaseDate: draft.releaseDate
            )
        }

        return await viewModel.createPlatformRelease(
            platformId: platformId,
            region: draft.region,
            releaseDate: draft.releaseDate
        )
    }
}
