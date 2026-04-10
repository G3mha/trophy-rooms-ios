import SwiftUI

struct AdminBundlesView: View {
    @StateObject private var viewModel = AdminBundlesViewModel()
    @State private var selectedType: BundleType?
    @State private var showingCreateSheet = false
    @State private var bundleToEdit: AppBundle?
    @State private var bundleToDelete: AppBundle?
    @State private var showingDeleteConfirmation = false
    @State private var selectedIds: Set<String> = []
    @State private var isSelecting = false
    @State private var showingBulkDeleteConfirmation = false
    @State private var bundleToManageContents: AppBundle?

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
            } header: {
                Text("Filter")
            }

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
                        HStack(spacing: 12) {
                            if isSelecting {
                                Image(systemName: selectedIds.contains(bundle.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedIds.contains(bundle.id) ? .blue : .gray)
                                    .onTapGesture {
                                        toggleSelection(bundle.id)
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
                                    if let platform = bundle.platform {
                                        Text(platform.name)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text("•")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    Text(bundle.slug)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    BundleTypeBadge(type: bundle.type)
                                }
                                HStack(spacing: 8) {
                                    if bundle.gameFamilyCount > 0 {
                                        Text("\(bundle.gameFamilyCount) games")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    if bundle.dlcCount > 0 {
                                        Text("\(bundle.dlcCount) DLCs")
                                            .font(.caption2)
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
                            if isSelecting {
                                toggleSelection(bundle.id)
                            } else {
                                bundleToEdit = bundle
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if !isSelecting {
                                Button(role: .destructive) {
                                    bundleToDelete = bundle
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    bundleToEdit = bundle
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                        .swipeActions(edge: .leading) {
                            if !isSelecting {
                                Button {
                                    bundleToManageContents = bundle
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
        .navigationTitle("Bundles")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isSelecting {
                    Button("Done") {
                        isSelecting = false
                        selectedIds.removeAll()
                    }
                } else {
                    Menu {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            Label("Add Bundle", systemImage: "plus")
                        }

                        Button {
                            isSelecting = true
                        } label: {
                            Label("Select", systemImage: "checkmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelecting && !selectedIds.isEmpty {
                Button(role: .destructive) {
                    showingBulkDeleteConfirmation = true
                } label: {
                    Label("Delete \(selectedIds.count)", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding()
                .background(.bar)
            }
        }
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
            selectedIds.removeAll()
            isSelecting = false
        }
        .sheet(isPresented: $showingCreateSheet) {
            AdminBundleFormSheet(viewModel: viewModel, bundle: nil)
        }
        .sheet(item: $bundleToEdit) { bundle in
            AdminBundleFormSheet(viewModel: viewModel, bundle: bundle)
        }
        .sheet(item: $bundleToManageContents) { bundle in
            AdminBundleContentsSheet(viewModel: viewModel, bundleId: bundle.id)
        }
        .alert("Delete Bundle", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                bundleToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let bundle = bundleToDelete {
                    Task {
                        _ = await viewModel.deleteBundle(id: bundle.id)
                        bundleToDelete = nil
                    }
                }
            }
        } message: {
            if let bundle = bundleToDelete {
                Text("Are you sure you want to delete \"\(bundle.name)\"? This action cannot be undone.")
            }
        }
        .alert("Delete Bundles", isPresented: $showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    _ = await viewModel.bulkDeleteBundles(ids: Array(selectedIds))
                    selectedIds.removeAll()
                    isSelecting = false
                }
            }
        } message: {
            Text("Are you sure you want to delete \(selectedIds.count) bundle(s)? This action cannot be undone.")
        }
    }

    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
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

#Preview {
    NavigationStack {
        AdminBundlesView()
    }
}
