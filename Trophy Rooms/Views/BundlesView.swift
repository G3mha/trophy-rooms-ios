import SwiftUI

struct BundlesView: View {
    @EnvironmentObject private var authManager: AuthManager
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
            .listRowBackground(Cabinet.card)

            if viewModel.isLoading && viewModel.bundles.isEmpty {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
                .listRowBackground(Cabinet.card)
            } else if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                }
                .listRowBackground(Cabinet.card)
            } else if viewModel.bundles.isEmpty {
                Section {
                    Text("No bundles found")
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Cabinet.card)
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
                .listRowBackground(Cabinet.card)
            }
        }
        .scrollContentBackground(.hidden)
        .cabinetCanvas()
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
            CachedImageFixed(
                url: bundle.coverUrl,
                width: 60,
                height: 60,
                placeholderIcon: "shippingbox"
            )

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
        Tag(type.displayName, tint: badgeColor)
    }

    var badgeColor: Color {
        switch type {
        case .BUNDLE:
            return Cabinet.Tint.info
        case .SEASON_PASS:
            return Cabinet.Tint.violet
        case .COLLECTION:
            return Cabinet.Tint.warm
        case .SUBSCRIPTION:
            return Cabinet.Tint.positive
        }
    }
}

#Preview {
    NavigationStack {
        BundlesView()
    }
}
