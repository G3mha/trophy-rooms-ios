import Foundation

extension AdminGamesViewModel {
    /// Fetch a single game by ID for editing.
    func fetchGame(id: String) async {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.gameToEdit = nil
        }

        do {
            let response = try await api.fetchGame(id: id)
            DispatchQueue.main.async {
                guard let game = response.game else { return }

                let baseGameFamilyIds = game.baseGameFamilies?.map { $0.id } ?? []
                self.gameToEdit = AdminGameItem(
                    id: game.id,
                    gameFamilyId: game.gameFamilyId,
                    title: game.title,
                    description: game.description,
                    coverUrl: game.coverUrl,
                    type: game.type,
                    baseGameFamilyId: baseGameFamilyIds.first,
                    baseGameFamilyIds: baseGameFamilyIds,
                    baseGameFamilies: game.baseGameFamilies,
                    platformId: game.platform?.id,
                    platformName: game.platform?.name,
                    platformSlug: game.platform?.slug,
                    achievementSetCount: 0
                )
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
