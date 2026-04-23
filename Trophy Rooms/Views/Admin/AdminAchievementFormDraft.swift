import Foundation
import Combine

final class AdminAchievementFormDraft: ObservableObject {
    @Published var title: String
    @Published var achievementDescription: String
    @Published var iconUrl: String
    @Published var points: Int
    @Published var selectedTier: AchievementTier?

    init(achievement: AdminAchievement?) {
        self.title = achievement?.title ?? ""
        self.achievementDescription = achievement?.description ?? ""
        self.iconUrl = achievement?.iconUrl ?? ""
        self.points = achievement?.points ?? 10
        self.selectedTier = achievement?.tier
    }

    var isValid: Bool {
        !normalizedTitle.isEmpty && points >= 0
    }

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedDescription: String? {
        let value = achievementDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    var normalizedIconUrl: String? {
        let value = iconUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
