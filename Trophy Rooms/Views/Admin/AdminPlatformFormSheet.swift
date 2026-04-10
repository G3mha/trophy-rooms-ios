import SwiftUI

struct AdminPlatformFormSheet: View {
    @ObservedObject var viewModel: AdminPlatformsViewModel
    let platform: AdminPlatform?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var slug: String = ""
    @State private var description: String = ""
    @State private var consolePictureUrl: String = ""
    @State private var promotionalPictures: [String] = []
    @State private var releases: [PlatformRelease] = []
    @State private var isSaving = false
    @State private var showingAddReleaseSheet = false
    @State private var editingRelease: PlatformRelease?

    var isEditing: Bool {
        platform != nil
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !slug.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        AdminFormSheet(
            entityName: "Platform",
            isEditing: isEditing,
            isSaving: isSaving,
            isValid: isValid,
            errorMessage: viewModel.errorMessage,
            onCancel: { dismiss() },
            onSave: { save() }
        ) {
            Section("Platform Details") {
                NameTextField("Name", text: $name)
                SlugTextField("Slug", text: $slug)
            }

            Section("Description") {
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Console Picture") {
                URLTextField("Console Picture URL", text: $consolePictureUrl)

                if !consolePictureUrl.isEmpty, let url = URL(string: consolePictureUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }

            Section("Promotional Pictures") {
                ForEach(promotionalPictures.indices, id: \.self) { index in
                    HStack {
                        TextField("URL", text: Binding(
                            get: { promotionalPictures[index] },
                            set: { promotionalPictures[index] = $0 }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        Button(role: .destructive) {
                            promotionalPictures.remove(at: index)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }

                Button {
                    promotionalPictures.append("")
                } label: {
                    Label("Add Picture URL", systemImage: "plus")
                }
            }

            if isEditing {
                Section("Release Dates") {
                    ForEach(releases) { release in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(release.region)
                                    .font(.headline)
                                Text(formatReleaseDate(release.releaseDate))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                editingRelease = release
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.borderless)

                            Button(role: .destructive) {
                                Task {
                                    _ = await viewModel.deletePlatformRelease(id: release.id)
                                    if let platform = platform {
                                        releases = platform.releases ?? []
                                    }
                                }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    Button {
                        showingAddReleaseSheet = true
                    } label: {
                        Label("Add Release Date", systemImage: "plus")
                    }
                }
            }
        }
        .onAppear {
            if let platform = platform {
                name = platform.name
                slug = platform.slug
                description = platform.description ?? ""
                consolePictureUrl = platform.consolePictureUrl ?? ""
                promotionalPictures = platform.promotionalPictures ?? []
                releases = platform.releases ?? []
            }
        }
        .sheet(isPresented: $showingAddReleaseSheet) {
            if let platform = platform {
                PlatformReleaseFormSheet(
                    viewModel: viewModel,
                    platformId: platform.id,
                    release: nil
                ) {
                    Task {
                        await viewModel.fetchPlatforms()
                        if let updated = viewModel.platforms.first(where: { $0.id == platform.id }) {
                            releases = updated.releases ?? []
                        }
                    }
                }
            }
        }
        .sheet(item: $editingRelease) { release in
            if let platform = platform {
                PlatformReleaseFormSheet(
                    viewModel: viewModel,
                    platformId: platform.id,
                    release: release
                ) {
                    Task {
                        await viewModel.fetchPlatforms()
                        if let updated = viewModel.platforms.first(where: { $0.id == platform.id }) {
                            releases = updated.releases ?? []
                        }
                    }
                }
            }
        }
    }

    private func formatReleaseDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    private func save() {
        isSaving = true

        // Filter out empty promotional picture URLs
        let filteredPromoPictures = promotionalPictures.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        Task {
            let success: Bool
            if let platform = platform {
                success = await viewModel.updatePlatform(
                    id: platform.id,
                    name: name.trimmingCharacters(in: .whitespaces),
                    slug: slug.trimmingCharacters(in: .whitespaces),
                    description: description.isEmpty ? nil : description,
                    consolePictureUrl: consolePictureUrl.isEmpty ? nil : consolePictureUrl.trimmingCharacters(in: .whitespaces),
                    promotionalPictures: filteredPromoPictures
                )
            } else {
                success = await viewModel.createPlatform(
                    name: name.trimmingCharacters(in: .whitespaces),
                    slug: slug.trimmingCharacters(in: .whitespaces),
                    description: description.isEmpty ? nil : description,
                    consolePictureUrl: consolePictureUrl.isEmpty ? nil : consolePictureUrl.trimmingCharacters(in: .whitespaces),
                    promotionalPictures: filteredPromoPictures.isEmpty ? nil : filteredPromoPictures
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

// MARK: - Platform Release Form Sheet

struct PlatformReleaseFormSheet: View {
    @ObservedObject var viewModel: AdminPlatformsViewModel
    let platformId: String
    let release: PlatformRelease?
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var region: String = "NA"
    @State private var releaseDate: Date = Date()
    @State private var isSaving = false

    private let regions = ["NA", "EU", "JP", "AU", "OTHER"]

    var isEditing: Bool {
        release != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Region") {
                    Picker("Region", selection: $region) {
                        ForEach(regions, id: \.self) { r in
                            Text(regionDisplayName(r)).tag(r)
                        }
                    }
                }

                Section("Release Date") {
                    DatePicker("Date", selection: $releaseDate, displayedComponents: .date)
                }
            }
            .navigationTitle(isEditing ? "Edit Release" : "Add Release")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                if let release = release {
                    region = release.region
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: release.releaseDate) {
                        releaseDate = date
                    }
                }
            }
        }
    }

    private func regionDisplayName(_ region: String) -> String {
        switch region {
        case "NA": return "North America"
        case "EU": return "Europe"
        case "JP": return "Japan"
        case "AU": return "Australia"
        case "OTHER": return "Other"
        default: return region
        }
    }

    private func save() {
        isSaving = true

        Task {
            let success: Bool
            if let release = release {
                success = await viewModel.updatePlatformRelease(
                    id: release.id,
                    region: region,
                    releaseDate: releaseDate
                )
            } else {
                success = await viewModel.createPlatformRelease(
                    platformId: platformId,
                    region: region,
                    releaseDate: releaseDate
                )
            }

            DispatchQueue.main.async {
                isSaving = false
                if success {
                    onComplete()
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    AdminPlatformFormSheet(viewModel: AdminPlatformsViewModel(), platform: nil)
}
