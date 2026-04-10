import SwiftUI
import ClerkKit

struct BundlesView: View {
    @Environment(Clerk.self) private var clerk
    @StateObject private var viewModel = BundlesViewModel()
    @State private var selectedType: BundleType?

    var body: some View {
        List {
            Section {
                Picker("Type Filter", selection: $selectedType) {
                    Text("All Types").tag(nil as BundleType?)
                    ForEach(BundleType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type as BundleType?)
                    }
                }
                .pickerStyle(.menu)
            }

            if viewModel.isLoading && viewModel.bundles.isEmpty {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            } else if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
            } else if viewModel.bundles.isEmpty {
                Section {
                    Text("No bundles found")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(viewModel.bundles) { bundle in
                        NavigationLink {
                            BundleDetailView(bundleId: bundle.id)
                        } label: {
                            BundleRowView(bundle: bundle)
                        }
                    }
                }
            }
        }
        .navigationTitle("Bundles")
        .searchable(text: $viewModel.searchText, prompt: "Search bundles")
        .refreshable {
            await viewModel.fetchBundles(type: selectedType)
        }
        .task {
            await viewModel.fetchBundles(type: selectedType)
        }
        .onChange(of: selectedType) { _, newValue in
            Task {
                await viewModel.fetchBundles(type: newValue)
            }
        }
    }
}

private struct BundleRowView: View {
    let bundle: BundleListItem

    var body: some View {
        HStack(spacing: 12) {
            if let coverUrl = bundle.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "shippingbox")
                            .foregroundStyle(.gray)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(bundle.name)
                        .font(.headline)
                        .lineLimit(1)

                    BundleTypeTag(type: bundle.type)
                }

                if let description = bundle.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if bundle.gameFamilyCount > 0 {
                        Text("\(bundle.gameFamilyCount) games")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if bundle.dlcCount > 0 {
                        Text("\(bundle.dlcCount) DLCs")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct BundleTypeTag: View {
    let type: BundleType

    var body: some View {
        Text(type.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.2))
            .foregroundStyle(badgeColor)
            .cornerRadius(4)
    }

    var badgeColor: Color {
        switch type {
        case .BUNDLE:
            return .blue
        case .SEASON_PASS:
            return .purple
        case .COLLECTION:
            return .orange
        case .SUBSCRIPTION:
            return .green
        }
    }
}

#Preview {
    NavigationStack {
        BundlesView()
    }
}
