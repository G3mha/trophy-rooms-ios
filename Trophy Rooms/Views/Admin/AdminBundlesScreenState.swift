import Foundation
import Combine

final class AdminBundlesScreenState: ObservableObject {
    @Published var selectedType: BundleType?
    @Published var showingCreateSheet = false
    @Published var bundleToEdit: AppBundle?
    @Published var bundleToDelete: AppBundle?
    @Published var showingDeleteConfirmation = false
    @Published var selectedIds: Set<String> = []
    @Published var isSelecting = false
    @Published var showingBulkDeleteConfirmation = false
    @Published var bundleToManageContents: AppBundle?

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

    func presentDelete(for bundle: AppBundle) {
        bundleToDelete = bundle
        showingDeleteConfirmation = true
    }
}
