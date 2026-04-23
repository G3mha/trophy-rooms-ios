import Foundation
import Combine

final class AdminSetFormDraft: ObservableObject {
    @Published var title: String
    @Published var selectedType: AchievementSetType
    @Published var selectedVisibility: AchievementSetVisibility
    @Published var selectedGame: GameSummary?
    @Published var selectedVersionId: String
    @Published var selectedDlcId: String

    init(achievementSet: AdminAchievementSet?) {
        self.title = achievementSet?.title ?? ""
        self.selectedType = achievementSet?.typeEnum ?? .OFFICIAL
        self.selectedVisibility = achievementSet?.visibilityEnum ?? .PUBLIC
        self.selectedVersionId = achievementSet?.gameVersionId ?? ""
        self.selectedDlcId = achievementSet?.dlcId ?? ""

        if
            let achievementSet,
            let gameFamily = achievementSet.gameFamily,
            let gameFamilyId = achievementSet.gameFamilyId
        {
            self.selectedGame = GameSummary(
                id: gameFamily.id,
                title: gameFamily.title,
                description: nil,
                coverUrl: nil,
                type: nil,
                gameFamilyId: gameFamilyId,
                baseGameFamilyId: nil,
                baseGameFamilyIds: nil,
                platform: nil,
                achievementSetCount: 0,
                achievementCount: 0,
                trophyCount: 0
            )
        } else {
            self.selectedGame = nil
        }
    }

    var isValid: Bool {
        !normalizedTitle.isEmpty && selectedGame != nil
    }

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedVersionId: String? {
        selectedVersionId.isEmpty ? nil : selectedVersionId
    }

    var normalizedDlcId: String? {
        selectedDlcId.isEmpty ? nil : selectedDlcId
    }

    func handleGameChange(_: GameSummary?) {
        selectedVersionId = ""
        selectedDlcId = ""
    }
}
