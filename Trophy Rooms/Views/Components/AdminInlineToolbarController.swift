import Foundation

struct AdminInlineToolbarController {
    let entity: AdminContextEntity
    let gamesViewModel: AdminGamesViewModel

    var deleteAlertTitle: String {
        "Delete \(entityTypeName(for: entity.type))"
    }

    var deleteAlertMessage: String {
        "Are you sure you want to delete \"\(entity.title)\"? This action cannot be undone."
    }

    func deleteCurrentEntity(clearEntity: @escaping () -> Void) async -> Bool {
        let success: Bool

        switch entity.type {
        case .game:
            success = await gamesViewModel.deleteGame(id: entity.id)
        case .bundle, .dlc, .achievementSet:
            success = false
        }

        if success {
            clearEntity()
            NotificationCenter.default.post(name: .adminGameDidDelete, object: nil)
        }

        return success
    }

    private func entityTypeName(for type: AdminEntityType) -> String {
        switch type {
        case .game: return "Game"
        case .bundle: return "Bundle"
        case .dlc: return "DLC"
        case .achievementSet: return "Achievement Set"
        }
    }
}
