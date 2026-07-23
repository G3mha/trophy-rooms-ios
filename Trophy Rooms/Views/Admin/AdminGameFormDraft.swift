import Foundation
import Combine

final class AdminGameFormDraft: ObservableObject {
    @Published var title: String
    @Published var description: String
    @Published var coverUrl: String
    @Published var platformDescription: String
    @Published var platformCoverUrl: String
    @Published var selectedPlatformIds: Set<String>
    @Published var selectedType: GameType
    @Published var selectedBaseGameIds: Set<String>
    @Published var selectedBaseGames: [GameSummary]

    let excludedGameIds: Set<String>

    init(game: AdminGameItem?) {
        self.title = game?.title ?? ""
        self.description = game?.description ?? ""
        self.coverUrl = game?.coverUrl ?? ""
        self.platformDescription = game?.platformDescription ?? ""
        self.platformCoverUrl = game?.platformCoverUrl ?? ""
        self.selectedPlatformIds = game?.platformId.map { [$0] } ?? []
        self.selectedType = game?.type ?? .BASE_GAME

        if let baseGameFamilyIds = game?.baseGameFamilyIds {
            self.selectedBaseGameIds = Set(baseGameFamilyIds)
        } else if let baseGameFamilyId = game?.baseGameFamilyId {
            self.selectedBaseGameIds = [baseGameFamilyId]
        } else {
            self.selectedBaseGameIds = []
        }

        self.selectedBaseGames = game?.baseGameFamilies?.map { family in
            GameSummary(
                id: family.id,
                title: family.title,
                coverUrl: family.coverUrl,
                type: family.type
            )
        } ?? []

        self.excludedGameIds = game.map { [$0.id] } ?? []
    }

    var isValid: Bool {
        !normalizedTitle.isEmpty && !selectedPlatformIds.isEmpty
    }

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespaces)
    }

    var normalizedDescription: String? {
        let value = description.trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    var normalizedCoverUrl: String? {
        let value = coverUrl.trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    var normalizedPlatformDescription: String? {
        let value = platformDescription.trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    var normalizedPlatformCoverUrl: String? {
        let value = platformCoverUrl.trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    var normalizedBaseGameFamilyIds: [String]? {
        selectedBaseGameIds.isEmpty ? nil : Array(selectedBaseGameIds)
    }

    func handleTypeChange(_ newValue: GameType) {
        guard newValue == .BASE_GAME else { return }
        selectedBaseGameIds.removeAll()
        selectedBaseGames.removeAll()
    }
}
