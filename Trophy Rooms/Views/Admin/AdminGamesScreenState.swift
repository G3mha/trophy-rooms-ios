import Foundation
import Combine

final class AdminGamesScreenState: ObservableObject {
    @Published var showingCreateSheet = false
    @Published var gameToEdit: AdminGameItem?
    @Published var gameToDelete: AdminGameItem?
    @Published var showingDeleteConfirmation = false
    @Published var selectedIds: Set<String> = []
    @Published var isSelecting = false
    @Published var showingBulkDeleteConfirmation = false
    @Published var gameToClone: AdminGameItem?
    @Published var showingCloneSheet = false
    @Published var selectedPageSize = 50
    @Published var groupToAddPlatform: AdminGameGroup?

    func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    func finishSelection() {
        isSelecting = false
        selectedIds.removeAll()
    }

    func presentDelete(for game: AdminGameItem) {
        gameToDelete = game
        showingDeleteConfirmation = true
    }

    func presentClone(for game: AdminGameItem) {
        gameToClone = game
        showingCloneSheet = true
    }

    func deleteActionLabel(for game: AdminGameItem) -> String {
        game.gameFamilyId == nil ? "Delete" : "Remove Platform"
    }

    var deleteAlertTitle: String {
        guard let game = gameToDelete else { return "Delete Game" }
        return game.gameFamilyId == nil ? "Delete Game" : "Remove Platform"
    }

    func deleteAlertMessage(for game: AdminGameItem) -> String {
        if game.gameFamilyId != nil {
            return "Remove \(game.platformName ?? "this platform") from \"\(game.title)\"? This deletes that platform-specific entry, including all achievement sets and achievements attached to it. This action cannot be undone."
        }

        return "Are you sure you want to delete \"\(game.title)\"? This will also delete all achievement sets and achievements. This action cannot be undone."
    }
}
