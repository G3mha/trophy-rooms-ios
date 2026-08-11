import SwiftUI

struct AdminGamesPaginationSection: View {
    @ObservedObject var viewModel: AdminGamesViewModel
    @Binding var selectedPageSize: Int

    var body: some View {
        if viewModel.totalCount > 0 {
            Section {
                PaginationBar(
                    currentPage: viewModel.currentPage,
                    totalPages: viewModel.totalPages,
                    totalCount: viewModel.totalCount,
                    itemNoun: "games",
                    isLoading: viewModel.isLoading,
                    showsEndJumps: true
                ) { page in
                    Task { await viewModel.goToPage(page) }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                Picker("Per page", selection: $selectedPageSize) {
                    ForEach(PageSizeOption.allCases) { option in
                        Text(option.title).tag(option.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
                .listRowBackground(Cabinet.card)
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
