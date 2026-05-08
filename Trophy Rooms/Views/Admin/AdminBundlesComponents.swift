import SwiftUI

struct AdminBundlesFilterSection: View {
    @Binding var selectedType: BundleType?

    var body: some View {
        Section {
            Picker("Type Filter", selection: $selectedType) {
                Text("All Types").tag(nil as BundleType?)
                ForEach(BundleType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type as BundleType?)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Filter")
        }
    }
}

struct AdminBundlesListSection: View {
    @ObservedObject var viewModel: AdminBundlesViewModel
    @ObservedObject var screenState: AdminBundlesScreenState

    var body: some View {
        Section {
            if viewModel.isLoading && viewModel.bundles.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            } else if viewModel.bundles.isEmpty {
                Text("No bundles found")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.bundles, id: \.id) { bundle in
                    AdminBundleRow(
                        bundle: bundle,
                        isSelecting: screenState.isSelecting,
                        isSelected: screenState.selectedIds.contains(bundle.id),
                        onToggleSelection: { screenState.toggleSelection(bundle.id) },
                        onTap: {
                            if screenState.isSelecting {
                                screenState.toggleSelection(bundle.id)
                            } else {
                                screenState.bundleToEdit = bundle
                            }
                        }
                    )
                    .swipeActions(edge: .trailing) {
                        if !screenState.isSelecting {
                            Button(role: .destructive) {
                                screenState.presentDelete(for: bundle)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                screenState.bundleToEdit = bundle
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        if !screenState.isSelecting {
                            Button {
                                screenState.bundleToManageContents = bundle
                            } label: {
                                Label("Contents", systemImage: "list.bullet")
                            }
                            .tint(.orange)
                        }
                    }
                }
            }
        } header: {
            Text("Bundles")
        } footer: {
            if !viewModel.bundles.isEmpty {
                Text("Swipe left to edit or delete. Swipe right to manage contents.")
            }
        }
    }
}

struct AdminBundleRow: View {
    let bundle: AppBundle
    let isSelecting: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray)
                    .onTapGesture {
                        onToggleSelection()
                    }
            }

            if let coverUrl = bundle.coverUrl, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 50, height: 50)
                .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "shippingbox")
                            .foregroundStyle(.gray)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(bundle.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    if !bundle.platforms.isEmpty {
                        Text(bundle.platforms.map { $0.name }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if bundle.gameFamilyCount > 0 {
                        Text("\(bundle.gameFamilyCount) games")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    if bundle.dlcCount > 0 {
                        Text("\(bundle.dlcCount) DLCs")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
            if let price = bundle.price {
                Text(String(format: "$%.2f", price))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct BundleTypeBadge: View {
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
