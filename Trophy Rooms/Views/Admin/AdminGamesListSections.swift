import SwiftUI

struct AdminGamesPaginationSection: View {
    @ObservedObject var viewModel: AdminGamesViewModel
    @Binding var selectedPageSize: Int

    var body: some View {
        if viewModel.totalCount > 0 {
            Section {
                HStack(spacing: 16) {
                    Button {
                        Task { await viewModel.goToFirstPage() }
                    } label: {
                        Image(systemName: "chevron.backward.2")
                    }
                    .disabled(viewModel.currentPage == 1 || viewModel.isLoading)

                    Button {
                        Task { await viewModel.goToPreviousPage() }
                    } label: {
                        Image(systemName: "chevron.backward")
                    }
                    .disabled(!viewModel.canGoPrevious)

                    Spacer()

                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Page \(viewModel.currentPage) of \(viewModel.totalPages)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        Task { await viewModel.goToNextPage() }
                    } label: {
                        Image(systemName: "chevron.forward")
                    }
                    .disabled(!viewModel.canGoNext)

                    Button {
                        Task { await viewModel.goToLastPage() }
                    } label: {
                        Image(systemName: "chevron.forward.2")
                    }
                    .disabled(viewModel.currentPage == viewModel.totalPages || viewModel.isLoading)
                }
                .buttonStyle(.borderless)

                HStack {
                    Text("\(viewModel.totalCount) games total")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Picker("Per page", selection: $selectedPageSize) {
                        ForEach(PageSizeOption.allCases) { option in
                            Text(option.title).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.caption)
                }
            }
        }
    }
}

struct AdminGamesListContent: View {
    @ObservedObject var viewModel: AdminGamesViewModel
    let isSelecting: Bool
    let selectedIds: Set<String>
    let onToggleSelection: (String) -> Void
    let onEdit: (AdminGameItem) -> Void
    let onDelete: (AdminGameItem) -> Void
    let onClone: (AdminGameItem) -> Void
    let onAddPlatform: (AdminGameGroup) -> Void
    let deleteActionLabel: (AdminGameItem) -> String

    var body: some View {
        if viewModel.isLoading && viewModel.games.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if let error = viewModel.errorMessage {
            Text(error)
                .foregroundStyle(.red)
        } else if viewModel.isGrouped {
            ForEach(viewModel.groupedGames) { group in
                groupedContent(for: group)
            }
        } else {
            ForEach(viewModel.filteredGames) { game in
                gameRow(game)
            }
        }
    }

    @ViewBuilder
    private func groupedContent(for group: AdminGameGroup) -> some View {
        if group.isSingleGame, let game = group.games.first {
            gameRow(game)
        } else {
            DisclosureGroup {
                ForEach(group.games) { game in
                    gameRow(game, isSubRow: true)
                }

                if !isSelecting, group.gameFamilyId != nil {
                    Button {
                        onAddPlatform(group)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            Text("Add Platform")
                                .foregroundStyle(.blue)
                            Spacer()
                        }
                    }
                }
            } label: {
                AdminGameGroupRow(group: group)
            }
        }
    }

    private func gameRow(_ game: AdminGameItem, isSubRow: Bool = false) -> some View {
        AdminGameRow(
            game: game,
            isSelecting: isSelecting,
            isSelected: selectedIds.contains(game.id),
            onToggleSelection: { onToggleSelection(game.id) },
            onTap: {
                if isSelecting {
                    onToggleSelection(game.id)
                } else {
                    onEdit(game)
                }
            },
            isSubRow: isSubRow
        )
        .swipeActions(edge: .trailing) {
            if !isSelecting {
                Button(role: .destructive) {
                    onDelete(game)
                } label: {
                    Label(deleteActionLabel(game), systemImage: "trash")
                }

                Button {
                    onEdit(game)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)

                Button {
                    onClone(game)
                } label: {
                    Label("Clone", systemImage: "doc.on.doc")
                }
                .tint(.orange)
            }
        }
    }
}
