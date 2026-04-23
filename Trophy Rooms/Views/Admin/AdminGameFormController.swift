import Foundation

struct AdminGameFormController {
    let viewModel: AdminGamesViewModel
    let game: AdminGameItem?

    var isEditing: Bool {
        game != nil
    }

    var navigationTitle: String {
        isEditing ? "Edit Game" : "New Game"
    }

    var saveButtonTitle: String {
        isEditing ? "Save" : "Create"
    }

    func importFromIGDB(url: String) async -> Bool {
        await viewModel.importGameFamilyFromIGDBUrl(url: url)
    }

    var removeConfirmationMessage: String? {
        guard let game else { return nil }
        return "Remove \(game.platformName ?? "this platform") from \"\(game.title)\"? This deletes that platform-specific entry, including its achievement sets and achievements."
    }

    func save(draft: AdminGameFormDraft) async -> Bool {
        if let game {
            return await viewModel.updateGame(
                id: game.id,
                title: draft.normalizedTitle,
                description: draft.normalizedDescription,
                coverUrl: draft.normalizedCoverUrl,
                platformId: draft.selectedPlatformIds.first ?? "",
                type: draft.selectedType,
                baseGameFamilyIds: draft.normalizedBaseGameFamilyIds
            )
        }

        return await viewModel.createGameFamily(
            title: draft.normalizedTitle,
            description: draft.normalizedDescription,
            coverUrl: draft.normalizedCoverUrl,
            platformIds: Array(draft.selectedPlatformIds),
            type: draft.selectedType,
            baseGameFamilyIds: draft.normalizedBaseGameFamilyIds
        )
    }

    func removePlatformFromFamily() async -> Bool {
        guard let game else { return false }
        return await viewModel.deleteGame(id: game.id)
    }
}
