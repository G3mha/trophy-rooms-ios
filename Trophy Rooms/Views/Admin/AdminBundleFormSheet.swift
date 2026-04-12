import SwiftUI

struct AdminBundleFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminBundlesViewModel
    @StateObject private var platformsViewModel = AdminPlatformsViewModel()
    let bundle: AppBundle?

    @State private var name = ""
    @State private var slug = ""
    @State private var type: BundleType = .BUNDLE
    @State private var selectedPlatformIds: Set<String> = []
    @State private var bundleDescription = ""
    @State private var coverUrl = ""
    @State private var priceString = ""
    @State private var isSaving = false

    var isEditing: Bool { bundle != nil }

    var body: some View {
        NavigationStack {
            Form {
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

                Section {
                    PlatformSelectionField(
                        platforms: platformsViewModel.platforms,
                        selectedPlatformIds: $selectedPlatformIds,
                        allowsMultipleSelection: false,
                        isDisabled: false
                    )
                } header: {
                    Text("Platform")
                }

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

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Bundle" : "New Bundle")
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
                if let bundle = bundle {
                    name = bundle.name
                    slug = bundle.slug
                    type = bundle.type
                    if let platformId = bundle.platformId {
                        selectedPlatformIds = [platformId]
                    }
                    bundleDescription = bundle.description ?? ""
                    coverUrl = bundle.coverUrl ?? ""
                    if let price = bundle.price {
                        priceString = String(format: "%.2f", price)
                    }
                }
            }
            .task {
                await platformsViewModel.fetchPlatforms()
            }
        }
    }

    private func save() async {
        isSaving = true
        let price = Double(priceString)

        if let bundle = bundle {
            let success = await viewModel.updateBundle(
                id: bundle.id,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                slug: slug.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                description: bundleDescription.isEmpty ? nil : bundleDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                coverUrl: coverUrl.isEmpty ? nil : coverUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                price: price,
                platformId: selectedPlatformIds.first
            )
            if success {
                dismiss()
            }
        } else {
            let success = await viewModel.createBundle(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                slug: slug.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                description: bundleDescription.isEmpty ? nil : bundleDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                coverUrl: coverUrl.isEmpty ? nil : coverUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                price: price,
                platformId: selectedPlatformIds.first
            )
            if success {
                dismiss()
            }
        }
        isSaving = false
    }
}
