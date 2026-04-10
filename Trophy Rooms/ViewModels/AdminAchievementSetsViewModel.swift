import Foundation
import Combine

class AdminAchievementSetsViewModel: ObservableObject {
    @Published var achievementSets: [AdminAchievementSet] = []
    @Published var games: [AdminGame] = []
    @Published var versions: [GameVersion] = []
    @Published var dlcs: [DLC] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var searchText: String = ""

    var filteredSets: [AdminAchievementSet] {
        if searchText.isEmpty {
            return achievementSets
        }
        return achievementSets.filter { set in
            set.title.localizedCaseInsensitiveContains(searchText) ||
            (set.gameFamily?.title.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    func fetchAchievementSets() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetAchievementSets {
            achievementSets {
                id
                title
                type
                visibility
                gameFamilyId
                gameFamily {
                    id
                    title
                    slug
                }
                gameVersionId
                dlcId
                dlc {
                    id
                    name
                    slug
                    type
                }
                achievementCount
            }
        }
        """

        do {
            let response: AdminAchievementSetsResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.achievementSets = response.achievementSets
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func fetchGames() async {
        let query = """
        query GetGames {
            games(first: 500) {
                edges {
                    node {
                        id
                        gameFamilyId
                        title
                        description
                        coverUrl
                        type
                        baseGameFamilyId
                        platform {
                            id
                            name
                            slug
                        }
                        achievementSetCount
                    }
                }
            }
        }
        """

        do {
            let response: AdminGamesResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.games = response.games.edges.map { $0.node }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func fetchVersions(gameFamilyId: String) async {
        let query = """
        query GetGameVersions($gameFamilyId: ID!) {
            gameVersions(gameFamilyId: $gameFamilyId) {
                id
                name
                slug
                description
                coverUrl
                effectiveCoverUrl
                releaseDate
                isDefault
                games {
                    id
                    title
                }
                dlcs {
                    id
                    name
                    slug
                    type
                }
                dlcCount
                achievementSetCount
            }
        }
        """

        do {
            let response: GameVersionsResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["gameFamilyId": gameFamilyId]
            )
            DispatchQueue.main.async {
                self.versions = response.gameVersions
            }
        } catch {
            DispatchQueue.main.async {
                self.versions = []
            }
        }
    }

    func fetchDlcs(gameFamilyId: String) async {
        let query = """
        query GetDLCs($gameFamilyId: ID!) {
            dlcs(gameFamilyId: $gameFamilyId) {
                id
                name
                slug
                type
            }
        }
        """

        do {
            let response: DLCsResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["gameFamilyId": gameFamilyId]
            )
            DispatchQueue.main.async {
                self.dlcs = response.dlcs
            }
        } catch {
            DispatchQueue.main.async {
                self.dlcs = []
            }
        }
    }

    func createAchievementSet(title: String, type: AchievementSetType, visibility: AchievementSetVisibility, gameFamilyId: String, gameVersionId: String? = nil, dlcId: String? = nil) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation CreateAchievementSet($input: CreateAchievementSetInput!) {
            createAchievementSet(input: $input) {
                success
                achievementSet {
                    id
                    title
                    type
                    visibility
                    gameFamilyId
                    gameFamily {
                        id
                        title
                        slug
                    }
                    dlc {
                        id
                        name
                    }
                    achievementCount
                }
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "type": type.rawValue,
            "visibility": visibility.rawValue,
            "gameFamilyId": gameFamilyId
        ]

        if let gameVersionId = gameVersionId, !gameVersionId.isEmpty {
            input["gameVersionId"] = gameVersionId
        }

        if let dlcId = dlcId, !dlcId.isEmpty {
            input["dlcId"] = dlcId
        }

        let variables: [String: Any] = ["input": input]

        do {
            let response: CreateAchievementSetResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.createAchievementSet.success {
                await fetchAchievementSets()
                DispatchQueue.main.async {
                    self.successMessage = "Achievement set created successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create achievement set"
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func updateAchievementSet(id: String, title: String, type: AchievementSetType, visibility: AchievementSetVisibility, gameFamilyId: String, gameVersionId: String? = nil, dlcId: String? = nil) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation UpdateAchievementSet($id: ID!, $input: UpdateAchievementSetInput!) {
            updateAchievementSet(id: $id, input: $input) {
                success
                achievementSet {
                    id
                    title
                    type
                    visibility
                    gameFamilyId
                    gameFamily {
                        id
                        title
                        slug
                    }
                    dlc {
                        id
                        name
                    }
                    achievementCount
                }
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "type": type.rawValue,
            "visibility": visibility.rawValue,
            "gameFamilyId": gameFamilyId
        ]

        if let gameVersionId = gameVersionId {
            input["gameVersionId"] = gameVersionId.isEmpty ? NSNull() : gameVersionId
        }

        if let dlcId = dlcId {
            input["dlcId"] = dlcId.isEmpty ? NSNull() : dlcId
        }

        let variables: [String: Any] = [
            "id": id,
            "input": input
        ]

        do {
            let response: UpdateAchievementSetResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.updateAchievementSet.success {
                await fetchAchievementSets()
                DispatchQueue.main.async {
                    self.successMessage = "Achievement set updated successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update achievement set"
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func deleteAchievementSet(id: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation DeleteAchievementSet($id: ID!) {
            deleteAchievementSet(id: $id) {
                success
            }
        }
        """

        do {
            let response: DeleteAchievementSetResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            if response.deleteAchievementSet.success {
                DispatchQueue.main.async {
                    self.achievementSets.removeAll { $0.id == id }
                    self.successMessage = "Achievement set deleted successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete achievement set"
                }
                return false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func bulkDeleteAchievementSets(ids: [String]) async -> Int {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation BulkDeleteAchievementSets($ids: [ID!]!) {
            bulkDeleteAchievementSets(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        do {
            let response: BulkDeleteAchievementSetsResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["ids": ids]
            )
            if response.bulkDeleteAchievementSets.success {
                DispatchQueue.main.async {
                    self.achievementSets.removeAll { ids.contains($0.id) }
                    self.successMessage = "Deleted \(response.bulkDeleteAchievementSets.deletedCount) set(s)"
                }
                return response.bulkDeleteAchievementSets.deletedCount
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete achievement sets"
                }
                return 0
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return 0
        }
    }
}
