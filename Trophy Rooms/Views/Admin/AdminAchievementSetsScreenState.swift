import Foundation
import Combine

final class AdminAchievementSetsScreenState: ObservableObject {
    @Published var showingCreateSheet = false
    @Published var setToEdit: AdminAchievementSet?
    @Published var setToDelete: AdminAchievementSet?
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

    func presentDelete(for set: AdminAchievementSet) {
        setToDelete = set
        showingDeleteConfirmation = true
    }
}
