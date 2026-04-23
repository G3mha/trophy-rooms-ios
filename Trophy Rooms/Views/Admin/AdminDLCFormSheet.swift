import SwiftUI

struct AdminDLCFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminDLCsViewModel
    @StateObject private var draft: AdminDLCFormDraft
    let gameFamilyId: String
    let dlc: DLC?
    let availablePlatforms: [Platform]
    @State private var isSaving = false

    init(
        viewModel: AdminDLCsViewModel,
        gameFamilyId: String,
        dlc: DLC?,
        availablePlatforms: [Platform]
    ) {
        self.viewModel = viewModel
        self.gameFamilyId = gameFamilyId
        self.dlc = dlc
        self.availablePlatforms = availablePlatforms
        _draft = StateObject(wrappedValue: AdminDLCFormDraft(dlc: dlc))
    }

    private var controller: AdminDLCFormController {
        AdminDLCFormController(
            viewModel: viewModel,
            gameFamilyId: gameFamilyId,
            dlc: dlc
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                AdminDLCBasicInfoSection(
                    name: $draft.name,
                    slug: $draft.slug,
                    type: $draft.type,
                    isEditing: controller.isEditing
                )

                AdminDLCDetailsSection(
                    dlcDescription: $draft.dlcDescription,
                    coverUrl: $draft.coverUrl,
                    priceString: $draft.priceString
                )

                AdminDLCPlatformsSection(
                    availablePlatforms: availablePlatforms,
                    selectedPlatformIds: $draft.selectedPlatformIds
                )

                AdminDLCCoverPreviewSection(coverUrl: draft.coverUrl)

                if let error = viewModel.errorMessage {
                    AdminDLCErrorSection(error: error)
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
