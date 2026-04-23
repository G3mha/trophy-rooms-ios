import SwiftUI

struct PlatformReleaseFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminPlatformsViewModel
    @StateObject private var draft: PlatformReleaseFormDraft
    let platformId: String
    let release: PlatformRelease?
    let onComplete: () -> Void
    @State private var isSaving = false

    init(
        viewModel: AdminPlatformsViewModel,
        platformId: String,
        release: PlatformRelease?,
        onComplete: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.platformId = platformId
        self.release = release
        self.onComplete = onComplete
        _draft = StateObject(wrappedValue: PlatformReleaseFormDraft(release: release))
    }

    private var controller: PlatformReleaseFormController {
        PlatformReleaseFormController(
            viewModel: viewModel,
            platformId: platformId,
            release: release
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                PlatformReleaseRegionSection(region: $draft.region)
                PlatformReleaseDateSection(releaseDate: $draft.releaseDate)
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
                    Button("Save") {
                        Task {
                            await save()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private func save() async {
        isSaving = true

        let success = await controller.save(draft: draft)
        if success {
            onComplete()
            dismiss()
        }

        isSaving = false
    }
}
