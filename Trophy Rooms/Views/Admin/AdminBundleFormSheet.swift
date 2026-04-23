import SwiftUI

struct AdminBundleFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminBundlesViewModel
    @StateObject private var platformsViewModel = AdminPlatformsViewModel()
    @StateObject private var draft: AdminBundleFormDraft
    let bundle: AppBundle?
    @State private var isSaving = false

    init(viewModel: AdminBundlesViewModel, bundle: AppBundle?) {
        self.viewModel = viewModel
        self.bundle = bundle
        _draft = StateObject(wrappedValue: AdminBundleFormDraft(bundle: bundle))
    }

    private var controller: AdminBundleFormController {
        AdminBundleFormController(viewModel: viewModel, bundle: bundle)
    }

    var body: some View {
        NavigationStack {
            Form {
                AdminBundleBasicInfoSection(
                    name: $draft.name,
                    slug: $draft.slug,
                    type: $draft.type,
                    isEditing: controller.isEditing
                )

                AdminBundlePlatformSection(
                    platforms: platformsViewModel.platforms,
                    selectedPlatformIds: $draft.selectedPlatformIds
                )

                AdminBundleDetailsSection(
                    bundleDescription: $draft.bundleDescription,
                    coverUrl: $draft.coverUrl,
                    priceString: $draft.priceString
                )

                AdminBundleCoverPreviewSection(coverUrl: draft.coverUrl)

                if let error = viewModel.errorMessage {
                    AdminBundleErrorSection(error: error)
                }
            }
            .navigationTitle(controller.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(controller.saveButtonTitle) {
                        Task {
                            await save()
                        }
                    }
                    .disabled(!draft.isValid || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .task {
                await platformsViewModel.fetchPlatforms()
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
}
