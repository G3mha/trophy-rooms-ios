import SwiftUI

struct AdminDLCBasicInfoSection: View {
    @Binding var name: String
    @Binding var slug: String
    @Binding var type: DLCType
    let isEditing: Bool

    var body: some View {
        Section {
            TextField("Name", text: $name)
            AutoSlugTextField("Slug", slug: $slug, from: name, isEditing: isEditing)

            Picker("Type", selection: $type) {
                ForEach(DLCType.allCases, id: \.self) { dlcType in
                    Text(dlcType.displayName).tag(dlcType)
                }
            }
        } header: {
            Text("Basic Info")
        }
    }
}

struct AdminDLCDetailsSection: View {
    @Binding var dlcDescription: String
    @Binding var coverUrl: String
    @Binding var priceString: String

    var body: some View {
        Section {
            TextField("Description", text: $dlcDescription, axis: .vertical)
                .lineLimit(3...6)
            TextField("Cover URL", text: $coverUrl)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
            TextField("Price (optional)", text: $priceString)
                .keyboardType(.decimalPad)
        } header: {
            Text("Details")
        }
    }
}

struct AdminDLCPlatformsSection: View {
    let availablePlatforms: [Platform]
    @Binding var selectedPlatformIds: Set<String>

    var body: some View {
        Section {
            if availablePlatforms.isEmpty {
                Text("No platforms available")
                    .foregroundStyle(.secondary)
            } else {
                PlatformSelectionField(
                    platforms: availablePlatforms,
                    selectedPlatformIds: $selectedPlatformIds,
                    allowsMultipleSelection: true,
                    isDisabled: false
                )
            }
        } header: {
            Text("Available On")
        } footer: {
            Text("Select the platforms this DLC is available on.")
        }
    }
}

struct AdminDLCCoverPreviewSection: View {
    let coverUrl: String

    var body: some View {
        if !coverUrl.isEmpty, let url = URL(string: coverUrl) {
            Section {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
            } header: {
                Text("Cover Preview")
            }
        }
    }
}

struct AdminDLCErrorSection: View {
    let error: String

    var body: some View {
        Section {
            Text(error)
                .foregroundStyle(.red)
        }
    }
}
