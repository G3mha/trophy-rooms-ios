import SwiftUI

struct AdminDLCsView: View {
    @StateObject private var viewModel = AdminDLCsViewModel()
    @State private var selectedGame: GameSummary?
    @State private var showingGamePicker = false
    @State private var showingCreateSheet = false
    @State private var dlcToEdit: DLC?
    @State private var dlcToDelete: DLC?
    @State private var showingDeleteConfirmation = false
    @State private var selectedIds: Set<String> = []
    @State private var isSelecting = false
    @State private var showingBulkDeleteConfirmation = false

    var body: some View {
        List {
            gameSelectionSection

            if selectedGame != nil {
                dlcListSection
            }
        }
        .navigationTitle("DLCs & Expansions")
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { bulkDeleteButton }
        .refreshable {
            if let game = selectedGame {
                await viewModel.fetchDLCs(gameId: game.id)
            }
        }
        .onChange(of: selectedGame) { _, newValue in
            if let game = newValue {
                Task {
                    await viewModel.fetchDLCs(gameId: game.id)
                }
            } else {
                viewModel.dlcs = []
            }
            selectedIds.removeAll()
            isSelecting = false
        }
        .sheet(isPresented: $showingGamePicker) {
            GamePickerSheet(title: "Select Game") { game in
                selectedGame = game
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            if let game = selectedGame {
                AdminDLCFormSheet(viewModel: viewModel, gameId: game.id, dlc: nil)
            }
        }
        .sheet(item: $dlcToEdit) { dlc in
            if let game = selectedGame {
                AdminDLCFormSheet(viewModel: viewModel, gameId: game.id, dlc: dlc)
            }
        }
        .alert("Delete DLC", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                dlcToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let dlc = dlcToDelete, let game = selectedGame {
                    Task {
                        await viewModel.deleteDLC(id: dlc.id, gameId: game.id)
                        dlcToDelete = nil
                    }
                }
            }
        } message: {
            if let dlc = dlcToDelete {
                Text("Are you sure you want to delete \"\(dlc.name)\"? This action cannot be undone.")
            }
        }
        .alert("Delete DLCs", isPresented: $showingBulkDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let game = selectedGame {
                    Task {
                        await viewModel.bulkDeleteDLCs(ids: Array(selectedIds), gameId: game.id)
                        selectedIds.removeAll()
                        isSelecting = false
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete \(selectedIds.count) DLC(s)? This action cannot be undone.")
        }
    }

    // MARK: - Game Selection Section

    private var gameSelectionSection: some View {
        Section {
            Button {
                showingGamePicker = true
            } label: {
                GameSelectorRow(selectedGame: selectedGame)
            }
        } header: {
            Text("Select Game")
        }
    }

    // MARK: - DLC List Section

    private var dlcListSection: some View {
        Section {
            if viewModel.isLoading && viewModel.dlcs.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            } else if viewModel.dlcs.isEmpty {
                Text("No DLCs found")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.dlcs, id: \.id) { dlc in
                    DLCListRow(
                        dlc: dlc,
                        isSelecting: isSelecting,
                        isSelected: selectedIds.contains(dlc.id),
                        onTap: {
                            if isSelecting {
                                toggleSelection(dlc.id)
                            } else {
                                dlcToEdit = dlc
                            }
                        },
                        onToggleSelection: { toggleSelection(dlc.id) },
                        onEdit: { dlcToEdit = dlc },
                        onDelete: {
                            dlcToDelete = dlc
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
        } header: {
            Text("DLCs & Expansions")
        } footer: {
            if !viewModel.dlcs.isEmpty {
                Text("Swipe left to edit or delete.")
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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
                            Label("Add DLC", systemImage: "plus")
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

    // MARK: - Bulk Delete Button

    @ViewBuilder
    private var bulkDeleteButton: some View {
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

    // MARK: - Helpers

    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }
}

// MARK: - Game Selector Row

private struct GameSelectorRow: View {
    let selectedGame: GameSummary?

    var body: some View {
        HStack {
            Text("Game")
                .foregroundStyle(.primary)
            Spacer()
            if let game = selectedGame {
                HStack(spacing: 8) {
                    if let platform = game.platform {
                        PlatformIcon(slug: platform.slug, size: 14)
                    }
                    Text(game.title)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("Select a game")
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - DLC List Row

private struct DLCListRow: View {
    let dlc: DLC
    let isSelecting: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onToggleSelection: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray)
                    .onTapGesture { onToggleSelection() }
            }

            coverImage

            VStack(alignment: .leading, spacing: 4) {
                Text(dlc.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(dlc.slug)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    DLCTypeBadge(type: dlc.type)
                }
                if let price = dlc.price {
                    Text(String(format: "$%.2f", price))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if let count = dlc.achievementSetCount, count > 0 {
                Text("\(count) sets")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .swipeActions(edge: .trailing) {
            if !isSelecting {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
    }

    @ViewBuilder
    private var coverImage: some View {
        if let coverUrl = dlc.effectiveCoverUrl, let url = URL(string: coverUrl) {
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
        AdminDLCsView()
    }
}
