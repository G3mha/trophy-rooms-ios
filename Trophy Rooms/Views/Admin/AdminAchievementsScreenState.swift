import Foundation
import Combine

final class AdminAchievementsScreenState: ObservableObject {
    @Published var showingSetPicker = false
    @Published var showingCreateSheet = false
    @Published var showingCSVImportSheet = false
    @Published var achievementToEdit: AdminAchievement?
    @Published var achievementToDelete: AdminAchievement?
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

    func presentDelete(for achievement: AdminAchievement) {
        achievementToDelete = achievement
        showingDeleteConfirmation = true
    }
}
