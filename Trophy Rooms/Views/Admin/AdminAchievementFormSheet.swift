import SwiftUI

struct AdminAchievementFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminAchievementsViewModel
    @StateObject private var draft: AdminAchievementFormDraft
    let achievement: AdminAchievement?
    @State private var isSaving = false

    init(viewModel: AdminAchievementsViewModel, achievement: AdminAchievement?) {
        self.viewModel = viewModel
        self.achievement = achievement
        _draft = StateObject(wrappedValue: AdminAchievementFormDraft(achievement: achievement))
    }

    private var controller: AdminAchievementFormController {
        AdminAchievementFormController(viewModel: viewModel, achievement: achievement)
    }

    var body: some View {
        NavigationStack {
            Form {
                AdminAchievementDetailsSection(
                    title: $draft.title,
                    description: $draft.achievementDescription
                )

                AdminAchievementPointsTierSection(
                    points: $draft.points,
                    selectedTier: $draft.selectedTier
                )

                AdminAchievementIconSection(iconUrl: $draft.iconUrl)

                AdminAchievementIconPreviewSection(iconUrl: draft.iconUrl)

                if let error = viewModel.errorMessage {
                    AdminAchievementErrorSection(error: error)
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

#Preview {
    AdminAchievementFormSheet(viewModel: AdminAchievementsViewModel(), achievement: nil)
}
