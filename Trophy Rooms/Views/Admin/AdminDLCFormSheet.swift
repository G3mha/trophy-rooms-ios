import SwiftUI

struct AdminDLCFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminDLCsViewModel
    let gameFamilyId: String
    let dlc: DLC?
    let availablePlatforms: [Platform]

    @State private var name = ""
    @State private var slug = ""
    @State private var type: DLCType = .DLC
    @State private var dlcDescription = ""
    @State private var coverUrl = ""
    @State private var priceString = ""
    @State private var selectedPlatformIds: Set<String> = []
    @State private var isSaving = false

    var isEditing: Bool { dlc != nil }

    var body: some View {
        NavigationStack {
            Form {
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

                Section {
                    if availablePlatforms.isEmpty {
                        Text("No platforms available")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(availablePlatforms) { platform in
                            Button {
                                if selectedPlatformIds.contains(platform.id) {
                                    selectedPlatformIds.remove(platform.id)
                                } else {
                                    selectedPlatformIds.insert(platform.id)
                                }
                            } label: {
                                HStack {
                                    Text(platform.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedPlatformIds.contains(platform.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Available On")
                } footer: {
                    Text("Select the platforms this DLC is available on.")
                }

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

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit DLC" : "New DLC")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        Task {
                            await save()
                        }
                    }
                    .disabled(name.isEmpty || slug.isEmpty || isSaving)
                }
            }
            .interactiveDismissDisabled(isSaving)
            .onAppear {
                if let dlc = dlc {
                    name = dlc.name
                    slug = dlc.slug
                    type = dlc.type
                    dlcDescription = dlc.description ?? ""
                    coverUrl = dlc.coverUrl ?? ""
                    if let price = dlc.price {
                        priceString = String(format: "%.2f", price)
                    }
                    // Initialize selected platforms from existing DLC
                    if let platforms = dlc.platforms {
                        selectedPlatformIds = Set(platforms.map { $0.id })
                    }
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        let price = Double(priceString)
        let platformIds = Array(selectedPlatformIds)

        if let dlc = dlc {
            let success = await viewModel.updateDLC(
                id: dlc.id,
                gameFamilyId: gameFamilyId,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                slug: slug.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                description: dlcDescription.isEmpty ? nil : dlcDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                coverUrl: coverUrl.isEmpty ? nil : coverUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                price: price,
                platformIds: platformIds
            )
            if success {
                dismiss()
            }
        } else {
            let success = await viewModel.createDLC(
                gameFamilyId: gameFamilyId,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                slug: slug.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                description: dlcDescription.isEmpty ? nil : dlcDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                coverUrl: coverUrl.isEmpty ? nil : coverUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                price: price,
                platformIds: platformIds
            )
            if success {
                dismiss()
            }
        }
        isSaving = false
    }
}
