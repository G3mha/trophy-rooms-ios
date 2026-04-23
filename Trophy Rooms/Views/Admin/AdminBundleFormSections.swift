import SwiftUI

struct AdminBundleBasicInfoSection: View {
    @Binding var name: String
    @Binding var slug: String
    @Binding var type: BundleType
    let isEditing: Bool

    var body: some View {
        Section {
            TextField("Name", text: $name)
            AutoSlugTextField("Slug", slug: $slug, from: name, isEditing: isEditing)

            Picker("Type", selection: $type) {
                ForEach(BundleType.allCases, id: \.self) { bundleType in
                    Text(bundleType.displayName).tag(bundleType)
                }
            }
        } header: {
            Text("Basic Info")
        }
    }
}

struct AdminBundlePlatformSection: View {
    let platforms: [AdminPlatform]
    @Binding var selectedPlatformIds: Set<String>

    var body: some View {
        Section {
            PlatformSelectionField(
                platforms: platforms,
                selectedPlatformIds: $selectedPlatformIds,
                allowsMultipleSelection: false,
                isDisabled: false
            )
        } header: {
            Text("Platform")
        }
    }
}

struct AdminBundleDetailsSection: View {
    @Binding var bundleDescription: String
    @Binding var coverUrl: String
    @Binding var priceString: String

    var body: some View {
        Section {
            TextField("Description", text: $bundleDescription, axis: .vertical)
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

struct AdminBundleCoverPreviewSection: View {
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

struct AdminBundleErrorSection: View {
    let error: String

    var body: some View {
        Section {
            Text(error)
                .foregroundStyle(.red)
        }
    }
}
