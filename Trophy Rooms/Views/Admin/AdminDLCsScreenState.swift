import Foundation
import Combine

final class AdminDLCsScreenState: ObservableObject {
    @Published var selectedGame: GameSummary?
    @Published var showingCreateSheet = false
    @Published var dlcToEdit: DLC?
    @Published var dlcToDelete: DLC?
    @Published var showingDeleteConfirmation = false
    @Published var selectedIds: Set<String> = []
    @Published var isSelecting = false
    @Published var showingBulkDeleteConfirmation = false

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

    func presentDelete(for dlc: DLC) {
        dlcToDelete = dlc
        showingDeleteConfirmation = true
    }
}
