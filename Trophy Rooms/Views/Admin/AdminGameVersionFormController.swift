import Foundation

struct AdminGameVersionFormController {
    let viewModel: AdminGameVersionsViewModel
    let api: AdminGameVersionsAPI
    let gameFamilyId: String
    let version: GameVersion?

    var isEditing: Bool {
        version != nil
    }

    var navigationTitle: String {
        isEditing ? "Edit Version" : "New Version"
    }

    var saveButtonTitle: String {
        isEditing ? "Save" : "Create"
    }

    func fetchFamilyGames() async -> [FamilyGame] {
        do {
            let response = try await api.fetchFamilyGames(gameFamilyId: gameFamilyId)
            return response.gameFamily?.games ?? []
        } catch {
            return []
        }
    }

    func fetchAvailableDlcs() async -> [DLC] {
        do {
            let response = try await api.fetchAvailableDlcs(gameFamilyId: gameFamilyId)
            return response.dlcs
        } catch {
            return []
        }
    }

    func save(draft: AdminGameVersionFormDraft) async -> Bool {
        let gameIds = Array(draft.selectedGameIds)

        if let version {
            return await viewModel.updateVersion(
                id: version.id,
                gameFamilyId: gameFamilyId,
                gameIds: gameIds,
                name: draft.normalizedName,
                slug: draft.normalizedSlug,
                description: draft.normalizedDescription,
                coverUrl: draft.normalizedCoverUrl,
                dlcIds: draft.normalizedDlcIds,
                digitalOnly: draft.digitalOnly
            )
        }

        return await viewModel.createVersion(
            gameFamilyId: gameFamilyId,
            gameIds: gameIds,
            name: draft.normalizedName,
            slug: draft.normalizedSlug,
            description: draft.normalizedDescription,
            coverUrl: draft.normalizedCoverUrl,
            dlcIds: draft.normalizedDlcIds,
            isDefault: draft.isDefault,
            digitalOnly: draft.digitalOnly
        )
    }
}

struct GameFamilyGamesResponse: Decodable {
    let gameFamily: GameFamilyWithGames?
}

struct GameFamilyWithGames: Decodable {
    let games: [FamilyGame]
}

struct FamilyGame: Identifiable, Decodable {
    let id: String
    let platform: Platform?
}
