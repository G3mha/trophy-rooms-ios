import Foundation
import Combine

final class AdminGameVersionsScreenState: ObservableObject {
    @Published var selectedGame: GameSummary?
    @Published var showingCreateSheet = false
    @Published var versionToEdit: GameVersion?
    @Published var versionToDelete: GameVersion?
    @Published var showingDeleteConfirmation = false
    @Published var selectedIds: Set<String> = []
    @Published var isSelecting = false
    @Published var showingBulkDeleteConfirmation = false
    @Published var versionToSetDefault: GameVersion?
    @Published var showingSetDefaultConfirmation = false

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

    func nonDefaultSelectedIds(in versions: [GameVersion]) -> [String] {
        Array(selectedIds.filter { id in
            !versions.contains { $0.id == id && $0.isDefault }
        })
    }
}
