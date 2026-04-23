import Foundation

// MARK: - Admin Game Group

struct AdminGameGroup: Identifiable {
    let gameFamilyId: String?
    let title: String
    let coverUrl: String?
    let games: [AdminGameItem]

    var id: String { gameFamilyId ?? games.first?.id ?? UUID().uuidString }

    var isSingleGame: Bool { games.count == 1 }

    var platforms: [String] {
        games.compactMap { $0.platformName }
    }

    var totalAchievementSets: Int {
        games.reduce(0) { $0 + $1.achievementSetCount }
    }
}

extension AdminGamesViewModel {
    var filteredGames: [AdminGameItem] {
        // Search is handled server-side.
        games
    }

    var groupedGames: [AdminGameGroup] {
        var groups: [String: [AdminGameItem]] = [:]
        var noFamilyGames: [AdminGameItem] = []

        for game in games {
            if let familyId = game.gameFamilyId {
                groups[familyId, default: []].append(game)
            } else {
                noFamilyGames.append(game)
            }
        }

        var result: [AdminGameGroup] = groups.map { familyId, familyGames in
            let firstGame = familyGames[0]
            return AdminGameGroup(
                gameFamilyId: familyId,
                title: firstGame.title,
                coverUrl: firstGame.coverUrl,
                games: familyGames.sorted { ($0.platformName ?? "") < ($1.platformName ?? "") }
            )
        }

        result.append(contentsOf: noFamilyGames.map { game in
            AdminGameGroup(
                gameFamilyId: nil,
                title: game.title,
                coverUrl: game.coverUrl,
                games: [game]
            )
        })

        return result.sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    func baseGameForId(_ id: String) -> AdminGameItem? {
        games.first { $0.id == id }
    }
}
