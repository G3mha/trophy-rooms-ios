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
            Text("Trophy Details")
        }
    }
}

struct AdminAchievementTierSection: View {
    @Binding var selectedTier: AchievementTier?

    var body: some View {
        Section {
            Picker("Tier", selection: $selectedTier) {
                Text("None").tag(nil as AchievementTier?)
                ForEach(AchievementTier.allCases, id: \.self) { tier in
                    Text(tier.rawValue.capitalized).tag(tier as AchievementTier?)
                }
            }
        } header: {
            Text("Tier")
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
        if !iconUrl.isEmpty, URL(string: iconUrl) != nil {
            Section {
                RemoteImage(url: iconUrl, contentMode: .fit, icon: "photo")
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
