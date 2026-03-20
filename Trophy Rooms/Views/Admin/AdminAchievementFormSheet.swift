import SwiftUI

struct AdminAchievementFormSheet: View {
    @ObservedObject var viewModel: AdminAchievementsViewModel
    let achievement: AdminAchievement?
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var iconUrl: String = ""
    @State private var points: Int = 10
    @State private var selectedTier: AchievementTier? = nil
    @State private var isSaving = false

    var isEditing: Bool {
        achievement != nil
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        points >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Achievement Details")
                }

                Section {
                    Stepper("Points: \(points)", value: $points, in: 0...1000, step: 5)

                    Picker("Tier", selection: $selectedTier) {
                        Text("None").tag(nil as AchievementTier?)
                        ForEach(AchievementTier.allCases, id: \.self) { tier in
                            Text(tier.rawValue.capitalized).tag(tier as AchievementTier?)
                        }
                    }
                } header: {
                    Text("Points & Tier")
                }

                Section {
                    TextField("Icon URL", text: $iconUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("Icon (Optional)")
                }

                if !iconUrl.isEmpty, let url = URL(string: iconUrl) {
                    Section {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                    } header: {
                        Text("Icon Preview")
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Achievement" : "New Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        save()
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
        .onAppear {
            if let achievement = achievement {
                title = achievement.title
                description = achievement.description ?? ""
                iconUrl = achievement.iconUrl ?? ""
                points = achievement.points
                selectedTier = achievement.tier
            }
        }
    }

    private func save() {
        isSaving = true

        Task {
            let success: Bool
            let desc = description.trimmingCharacters(in: .whitespaces).isEmpty ? nil : description.trimmingCharacters(in: .whitespaces)
            let icon = iconUrl.trimmingCharacters(in: .whitespaces).isEmpty ? nil : iconUrl.trimmingCharacters(in: .whitespaces)

            if let achievement = achievement {
                success = await viewModel.updateAchievement(
                    id: achievement.id,
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: desc,
                    iconUrl: icon,
                    points: points,
                    tier: selectedTier
                )
            } else {
                success = await viewModel.createAchievement(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: desc,
                    iconUrl: icon,
                    points: points,
                    tier: selectedTier,
                    achievementSetId: viewModel.selectedSetId
                )
            }

            DispatchQueue.main.async {
                isSaving = false
                if success {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    AdminAchievementFormSheet(viewModel: AdminAchievementsViewModel(), achievement: nil)
}
