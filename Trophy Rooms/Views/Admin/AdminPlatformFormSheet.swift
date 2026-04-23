import SwiftUI

struct AdminPlatformFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminPlatformsViewModel
    @StateObject private var draft: AdminPlatformFormDraft
    let platform: AdminPlatform?
    @State private var isSaving = false
    @State private var showingAddReleaseSheet = false
    @State private var editingRelease: PlatformRelease?

    init(viewModel: AdminPlatformsViewModel, platform: AdminPlatform?) {
        self.viewModel = viewModel
        self.platform = platform
        _draft = StateObject(wrappedValue: AdminPlatformFormDraft(platform: platform))
    }

    private var controller: AdminPlatformFormController {
        AdminPlatformFormController(viewModel: viewModel, platform: platform)
    }

    var body: some View {
        AdminFormSheet(
            entityName: "Platform",
            isEditing: controller.isEditing,
            isSaving: isSaving,
            isValid: draft.isValid,
            errorMessage: viewModel.errorMessage,
            onCancel: { dismiss() },
            onSave: {
                Task {
                    await save()
                }
            }
        ) {
            AdminPlatformBasicInfoSection(
                name: $draft.name,
                slug: $draft.slug,
                isEditing: controller.isEditing
            )

            AdminPlatformDescriptionSection(platformDescription: $draft.platformDescription)

            AdminPlatformConsolePictureSection(consolePictureUrl: $draft.consolePictureUrl)

            AdminPlatformPromotionalPicturesSection(promotionalPictures: $draft.promotionalPictures)

            AdminPlatformReleasesSection(
                releases: draft.releases,
                isEditing: controller.isEditing,
                onEdit: { editingRelease = $0 },
                onDelete: { release in
                    Task {
                        await deleteRelease(release)
                    }
                },
                onAdd: { showingAddReleaseSheet = true }
            )

            if let error = viewModel.errorMessage {
                AdminPlatformErrorSection(error: error)
            }
        }
        .sheet(isPresented: $showingAddReleaseSheet) {
            if let platform {
                PlatformReleaseFormSheet(
                    viewModel: viewModel,
                    platformId: platform.id,
                    release: nil
                ) {
                    syncReleases(platformId: platform.id)
                }
            }
        }
        .sheet(item: $editingRelease) { release in
            if let platform {
                PlatformReleaseFormSheet(
                    viewModel: viewModel,
                    platformId: platform.id,
                    release: release
                ) {
                    syncReleases(platformId: platform.id)
                }
            }
        }
    }

    private func save() async {
        isSaving = true

        let success = await controller.save(draft: draft)
        if success {
            dismiss()
        }

        isSaving = false
    }

    private func deleteRelease(_ release: PlatformRelease) async {
        let success = await viewModel.deletePlatformRelease(id: release.id)
        guard success, let platform else { return }
        syncReleases(platformId: platform.id)
    }

    private func syncReleases(platformId: String) {
        if let updated = viewModel.platforms.first(where: { $0.id == platformId }) {
            DispatchQueue.main.async {
                draft.releases = updated.releases ?? []
            }
        }
    }
}

#Preview {
    AdminPlatformFormSheet(viewModel: AdminPlatformsViewModel(), platform: nil)
}
