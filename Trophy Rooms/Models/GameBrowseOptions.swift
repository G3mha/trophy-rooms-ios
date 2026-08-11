import SwiftUI

// Filter and sort options for the games browse grid. Extracted from the
// retired GameListView so the browse surface owns them directly.

enum AchievementFilter: String, CaseIterable, Identifiable {
    case all
    case withAchievements
    case withoutAchievements

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .withAchievements:
            return "With Achievements"
        case .withoutAchievements:
            return "Without Achievements"
        }
    }

    var boolValue: Bool? {
        switch self {
        case .all:
            return nil
        case .withAchievements:
            return true
        case .withoutAchievements:
            return false
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case titleAsc
    case titleDesc
    case newest
    case oldest
    case mostAchievements
    case mostTrophies

    var id: String { rawValue }

    var title: String {
        switch self {
        case .titleAsc:
            return "Title (A → Z)"
        case .titleDesc:
            return "Title (Z → A)"
        case .newest:
            return "Newest"
        case .oldest:
            return "Oldest"
        case .mostAchievements:
            return "Most Achievements"
        case .mostTrophies:
            return "Most Trophies"
        }
    }

    var graphqlValue: String {
        switch self {
        case .titleAsc:
            return "TITLE_ASC"
        case .titleDesc:
            return "TITLE_DESC"
        case .newest:
            return "CREATED_AT_DESC"
        case .oldest:
            return "CREATED_AT_ASC"
        case .mostAchievements:
            return "ACHIEVEMENT_COUNT_DESC"
        case .mostTrophies:
            return "TROPHY_COUNT_DESC"
        }
    }
}

enum MinAchievementOption: Int, CaseIterable, Identifiable {
    case any = 0
    case five = 5
    case ten = 10
    case twentyFive = 25

    var id: Int { rawValue }

    var value: Int { rawValue }

    var title: String {
        switch self {
        case .any:
            return "Any"
        case .five:
            return "5+"
        case .ten:
            return "10+"
        case .twentyFive:
            return "25+"
        }
    }
}

enum GameTypeFilter: String, CaseIterable, Identifiable {
    case all
    case baseGames
    case fangames
    case romHacks

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Types"
        case .baseGames:
            return "Base Games"
        case .fangames:
            return "Fangames"
        case .romHacks:
            return "ROM Hacks"
        }
    }

    var graphqlValue: String? {
        switch self {
        case .all:
            return nil
        case .baseGames:
            return "BASE_GAME"
        case .fangames:
            return "FANGAME"
        case .romHacks:
            return "ROM_HACK"
        }
    }
}

// MARK: - Game Row View (Single Platform)

