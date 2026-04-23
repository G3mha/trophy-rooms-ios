import Foundation
import Combine

final class AdminInlineToolbarState: ObservableObject {
    @Published var showEditSheet = false
    @Published var showCloneSheet = false
    @Published var showDeleteConfirmation = false
    @Published var isDeleting = false

    func presentEdit() {
        showEditSheet = true
    }

    func presentClone() {
        showCloneSheet = true
    }

    func presentDeleteConfirmation() {
        showDeleteConfirmation = true
    }
}
