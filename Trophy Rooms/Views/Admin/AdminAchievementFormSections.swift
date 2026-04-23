import SwiftUI

struct AdminAchievementDetailsSection: View {
    @Binding var title: String
    @Binding var description: String

    var body: some View {
        Section {
            TextField("Title", text: $title)

            TextField("Description", text: $description, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Achievement Details")
        }
    }
}

struct AdminAchievementPointsTierSection: View {
    @Binding var points: Int
    @Binding var selectedTier: AchievementTier?

    var body: some View {
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
    }
}

struct AdminAchievementIconSection: View {
    @Binding var iconUrl: String

    var body: some View {
        Section {
            TextField("Icon URL", text: $iconUrl)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
        } header: {
            Text("Icon (Optional)")
        }
    }
}

struct AdminAchievementIconPreviewSection: View {
    let iconUrl: String

    var body: some View {
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
    }
}

struct AdminAchievementErrorSection: View {
    let error: String

    var body: some View {
        Section {
            Text(error)
                .foregroundStyle(.red)
        }
    }
}
