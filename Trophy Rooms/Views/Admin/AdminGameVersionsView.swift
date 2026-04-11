import SwiftUI

struct AdminGameVersionsView: View {
    @StateObject private var viewModel = AdminGameVersionsViewModel()
    @State private var selectedGame: GameSummary?
    @State private var showingCreateSheet = false
    @State private var versionToEdit: GameVersion?
    @State private var versionToDelete: GameVersion?
    @State private var showingDeleteConfirmation = false
    @State private var selectedIds: Set<String> = []
    @State private var isSelecting = false
    @State private var showingBulkDeleteConfirmation = false
    @State private var versionToSetDefault: GameVersion?
    @State private var showingSetDefaultConfirmation = false

    var body: some View {
        List {
            Section {
                GameSelectorField(
                    title: "Game",
                    selectedGame: $selectedGame
                )
            } header: {
                Text("Select Game")
            }

            if selectedGame != nil {
                Section {
                    if viewModel.isLoading && viewModel.versions.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    } else if viewModel.versions.isEmpty {
                        Text("No versions found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.versions, id: \.id) { version in
                            VersionRow(
                                version: version,
                                isSelecting: isSelecting,
                                isSelected: selectedIds.contains(version.id),
                                onTap: {
                                    if isSelecting {
                                        toggleSelection(version.id)
                                    } else {
                                        versionToEdit = version
                                    }
                                },
                                onToggleSelection: { toggleSelection(version.id) },
                                onEdit: { versionToEdit = version },
                                onDelete: {
                                    versionToDelete = version
                                    showingDeleteConfirmation = true
                                },
                                onSetDefault: {
                                    versionToSetDefault = version
                                    showingSetDefaultConfirmation = true
                                }
                            )
                        }
                    }
                } header: {
                    Text("Versions")
                } footer: {
                    if !viewModel.versions.isEmpty {
                        Text("Swipe left to edit/delete, swipe right to set as default. Default version cannot be deleted.")
                    }
                }
            }
        }
        .navigationTitle("Game Versions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if selectedGame != nil {
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
                                Label("Add Version", systemImage: "plus")
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
        }
        .safeAreaInset(edge: .bottom) {
            if isSelecting && !selectedIds.isEmpty {
                let nonDefaultSelected = selectedIds.filter { id in
                    !viewModel.versions.contains { $0.id == id && $0.isDefault }
                }
                if !nonDefaultSelected.isEmpty {
                    Button(role: .destructive) {
                        showingBulkDeleteConfirmation = true
                    } label: {
                        Label("Delete \(nonDefaultSelected.count)", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding()
                    .background(.bar)
                }
            }
        }
        .refreshable {
            if let game = selectedGame {
                await viewModel.fetchVersions(gameId: game.id)
            }
        }
        .onChange(of: selectedGame) { _, newValue in
            if let game = newValue {
                Task {
                    await viewModel.fetchVersions(gameId: game.id)
                }
            } else {
                viewModel.versions = []
            }
            selectedIds.removeAll()
            isSelecting = false
        }
        .sheet(isPresented: $showingCreateSheet) {
            if let game = selectedGame, let gameFamilyId = game.gameFamilyId {
                AdminGameVersionFormSheet(viewModel: viewModel, gameFamilyId: gameFamilyId, version: nil)
            }
        }
        .sheet(item: $versionToEdit) { version in
            if let game = selectedGame, let gameFamilyId = game.gameFamilyId {
                AdminGameVersionFormSheet(viewModel: viewModel, gameFamilyId: gameFamilyId, version: version)
            }
        }
        .alert("Delete Version", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                versionToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let version = versionToDelete, let game = selectedGame {
                    Task {
                        _ = await viewModel.deleteVersion(id: version.id, gameId: game.id)
                        versionToDelete = nil
                    }
                }
            }
        } message: {
            if let version = versionToDelete {
                Text("Are you sure you want to delete \"\(version.name)\"? This action cannot be undone.")
            }
        }
        .alert("Set Default Version", isPresented: $showingSetDefaultConfirmation) {
            Button("Cancel", role: .cancel) {
                versionToSetDefault = nil
            }
            Button("Set Default") {
                if let version = versionToSetDefault, let game = selectedGame {
                    Task {
                        _ = await viewModel.setDefaultVersion(id: version.id, gameId: game.id)
                        versionToSetDefault = nil
                    }
                }
            }
        } message: {
            if let version = versionToSetDefault {
                Text("Set \"\(version.name)\" as the default version for this game?")
            }
        }
        .alert("Delete Versions", isPresented: $showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let game = selectedGame {
                    let nonDefaultIds = Array(selectedIds.filter { id in
                        !viewModel.versions.contains { $0.id == id && $0.isDefault }
                    })
                    Task {
                        _ = await viewModel.bulkDeleteVersions(ids: nonDefaultIds, gameId: game.id)
                        selectedIds.removeAll()
                        isSelecting = false
                    }
                }
            }
        } message: {
            let nonDefaultCount = selectedIds.filter { id in
                !viewModel.versions.contains { $0.id == id && $0.isDefault }
            }.count
            Text("Are you sure you want to delete \(nonDefaultCount) version(s)? Default versions will be skipped. This action cannot be undone.")
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

// MARK: - Version Row

private struct VersionRow: View {
    let version: GameVersion
    let isSelecting: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleSelection: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSetDefault: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray)
                    .onTapGesture { onToggleSelection() }
            }

            coverImage

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(version.name)
                        .font(.headline)
                        .lineLimit(1)
                    if version.isDefault {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }
                Text(version.slug ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let dlcs = version.dlcs, !dlcs.isEmpty {
                    Text("\(dlcs.count) DLC included")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text("\(version.achievementSetCount ?? 0) sets")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .swipeActions(edge: .trailing) {
            if !isSelecting {
                if !version.isDefault {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }

                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
        .swipeActions(edge: .leading) {
            if !isSelecting && !version.isDefault {
                Button {
                    onSetDefault()
                } label: {
                    Label("Set Default", systemImage: "star")
                }
                .tint(.yellow)
            }
        }
    }

    @ViewBuilder
    private var coverImage: some View {
        if let coverUrl = version.effectiveCoverUrl, let url = URL(string: coverUrl) {
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
        }
    }
}

#Preview {
    NavigationStack {
        AdminGameVersionsView()
    }
}
