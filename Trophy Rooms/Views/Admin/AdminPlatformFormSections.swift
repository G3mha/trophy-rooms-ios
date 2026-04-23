import SwiftUI

struct AdminPlatformBasicInfoSection: View {
    @Binding var name: String
    @Binding var slug: String
    let isEditing: Bool

    var body: some View {
        Section("Platform Details") {
            NameTextField("Name", text: $name)
            AutoSlugTextField("Slug", slug: $slug, from: name, isEditing: isEditing)
        }
    }
}

struct AdminPlatformDescriptionSection: View {
    @Binding var platformDescription: String

    var body: some View {
        Section("Description") {
            TextField("Description", text: $platformDescription, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}

struct AdminPlatformConsolePictureSection: View {
    @Binding var consolePictureUrl: String

    var body: some View {
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
    }
}

struct AdminPlatformPromotionalPicturesSection: View {
    @Binding var promotionalPictures: [String]

    var body: some View {
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
    }
}

struct AdminPlatformReleasesSection: View {
    let releases: [PlatformRelease]
    let isEditing: Bool
    let onEdit: (PlatformRelease) -> Void
    let onDelete: (PlatformRelease) -> Void
    let onAdd: () -> Void

    var body: some View {
        if isEditing {
            Section("Release Dates") {
                ForEach(releases) { release in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(release.region)
                                .font(.headline)
                            Text(AdminPlatformReleaseFormatting.formatReleaseDate(release.releaseDate))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            onEdit(release)
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)

                        Button(role: .destructive) {
                            onDelete(release)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Button {
                    onAdd()
                } label: {
                    Label("Add Release Date", systemImage: "plus")
                }
            }
        }
    }
}

struct AdminPlatformErrorSection: View {
    let error: String

    var body: some View {
        Section {
            Text(error)
                .foregroundStyle(.red)
        }
    }
}

enum AdminPlatformReleaseFormatting {
    static func formatReleaseDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    static func regionDisplayName(_ region: String) -> String {
        switch region {
        case "NA": return "North America"
        case "EU": return "Europe"
        case "JP": return "Japan"
        case "AU": return "Australia"
        case "OTHER": return "Other"
        default: return region
        }
    }
}
