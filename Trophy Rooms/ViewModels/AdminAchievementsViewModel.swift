import Foundation
import Combine

class AdminAchievementsViewModel: ObservableObject {
    @Published var achievements: [AdminAchievement] = []
    @Published var achievementSets: [AdminAchievementSet] = []
    @Published var selectedSetId: String = ""
    @Published var currentSetTitle: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // CSV Import state
    @Published var csvPreviewData: [[String]] = []
    @Published var importResult: BulkCreateResult?

    func fetchAchievementSets() async {
        let query = """
        query GetAchievementSets {
            achievementSets {
                id
                title
                type
                visibility
                game {
                    id
                    title
                }
                achievementCount
            }
        }
        """

        do {
            let response: AdminAchievementSetsResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.achievementSets = response.achievementSets
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func fetchAchievements(setId: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.selectedSetId = setId
        }

        let query = """
        query GetAchievementSet($id: ID!) {
            achievementSet(id: $id) {
                id
                title
                achievements {
                    id
                    title
                    description
                    iconUrl
                    points
                    tier
                    achievementSetId
                }
            }
        }
        """

        do {
            let response: AdminAchievementsResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["id": setId]
            )
            DispatchQueue.main.async {
                if let set = response.achievementSet {
                    self.achievements = set.achievements
                    self.currentSetTitle = set.title
                } else {
                    self.achievements = []
                    self.currentSetTitle = ""
                }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func createAchievement(title: String, description: String?, iconUrl: String?, points: Int, tier: AchievementTier?, achievementSetId: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation CreateAchievement($input: CreateAchievementInput!) {
            createAchievement(input: $input) {
                success
                achievement {
                    id
                    title
                    description
                    iconUrl
                    points
                    tier
                    achievementSetId
                }
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "points": points,
            "achievementSetId": achievementSetId
        ]
        if let description = description, !description.isEmpty {
            input["description"] = description
        }
        if let iconUrl = iconUrl, !iconUrl.isEmpty {
            input["iconUrl"] = iconUrl
        }
        if let tier = tier {
            input["tier"] = tier.rawValue
        }

        let variables: [String: Any] = ["input": input]

        do {
            let response: CreateAchievementResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.createAchievement.success {
                await fetchAchievements(setId: achievementSetId)
                DispatchQueue.main.async {
                    self.successMessage = "Achievement created successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create achievement"
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

    func updateAchievement(id: String, title: String, description: String?, iconUrl: String?, points: Int, tier: AchievementTier?) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation UpdateAchievement($id: ID!, $input: UpdateAchievementInput!) {
            updateAchievement(id: $id, input: $input) {
                success
                achievement {
                    id
                    title
                    description
                    iconUrl
                    points
                    tier
                    achievementSetId
                }
            }
        }
        """

        var input: [String: Any] = [
            "title": title,
            "points": points
        ]
        if let description = description {
            input["description"] = description
        }
        if let iconUrl = iconUrl {
            input["iconUrl"] = iconUrl
        }
        if let tier = tier {
            input["tier"] = tier.rawValue
        }

        let variables: [String: Any] = [
            "id": id,
            "input": input
        ]

        do {
            let response: UpdateAchievementResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            if response.updateAchievement.success {
                if !selectedSetId.isEmpty {
                    await fetchAchievements(setId: selectedSetId)
                }
                DispatchQueue.main.async {
                    self.successMessage = "Achievement updated successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update achievement"
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

    func deleteAchievement(id: String) async -> Bool {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation DeleteAchievement($id: ID!) {
            deleteAchievement(id: $id) {
                success
            }
        }
        """

        do {
            let response: DeleteAchievementResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["id": id]
            )
            if response.deleteAchievement.success {
                DispatchQueue.main.async {
                    self.achievements.removeAll { $0.id == id }
                    self.successMessage = "Achievement deleted successfully"
                }
                return true
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete achievement"
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

    func bulkDeleteAchievements(ids: [String]) async -> Int {
        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
        }

        let mutation = """
        mutation BulkDeleteAchievements($ids: [ID!]!) {
            bulkDeleteAchievements(ids: $ids) {
                success
                deletedCount
            }
        }
        """

        do {
            let response: BulkDeleteAchievementsResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["ids": ids]
            )
            if response.bulkDeleteAchievements.success {
                DispatchQueue.main.async {
                    self.achievements.removeAll { ids.contains($0.id) }
                    self.successMessage = "Deleted \(response.bulkDeleteAchievements.deletedCount) achievement(s)"
                }
                return response.bulkDeleteAchievements.deletedCount
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete achievements"
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

    // MARK: - CSV Import

    func parseCSV(_ content: String) -> [[String]] {
        var result: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in content {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else if char == "\n" && !insideQuotes {
                currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                if !currentRow.allSatisfy({ $0.isEmpty }) {
                    result.append(currentRow)
                }
                currentRow = []
                currentField = ""
            } else if char != "\r" {
                currentField.append(char)
            }
        }

        // Handle last field/row
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
            if !currentRow.allSatisfy({ $0.isEmpty }) {
                result.append(currentRow)
            }
        }

        return result
    }

    func previewCSV(_ content: String) {
        let parsed = parseCSV(content)
        DispatchQueue.main.async {
            self.csvPreviewData = parsed
        }
    }

    func importCSV(achievementSetId: String) async -> Bool {
        guard csvPreviewData.count > 1 else {
            DispatchQueue.main.async {
                self.errorMessage = "No data to import (need header + at least one row)"
            }
            return false
        }

        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
            self.importResult = nil
        }

        let headers = csvPreviewData[0].map { $0.lowercased() }
        let dataRows = Array(csvPreviewData.dropFirst())

        // Find column indices
        let titleIndex = headers.firstIndex(of: "title") ?? headers.firstIndex(of: "name")
        let descriptionIndex = headers.firstIndex(of: "description") ?? headers.firstIndex(of: "desc")
        let pointsIndex = headers.firstIndex(of: "points") ?? headers.firstIndex(of: "point")
        let tierIndex = headers.firstIndex(of: "tier")
        let iconUrlIndex = headers.firstIndex(of: "iconurl") ?? headers.firstIndex(of: "icon_url") ?? headers.firstIndex(of: "icon")

        guard let titleIdx = titleIndex else {
            DispatchQueue.main.async {
                self.errorMessage = "CSV must have a 'title' or 'name' column"
            }
            return false
        }

        var achievements: [[String: Any]] = []

        for row in dataRows {
            guard row.count > titleIdx else { continue }

            let title = row[titleIdx]
            guard !title.isEmpty else { continue }

            var achievement: [String: Any] = ["title": title]

            if let descIdx = descriptionIndex, row.count > descIdx, !row[descIdx].isEmpty {
                achievement["description"] = row[descIdx]
            }

            if let ptsIdx = pointsIndex, row.count > ptsIdx, let points = Int(row[ptsIdx]) {
                achievement["points"] = points
            } else {
                achievement["points"] = 10 // default
            }

            if let tIdx = tierIndex, row.count > tIdx, !row[tIdx].isEmpty {
                let tierStr = row[tIdx].uppercased()
                if ["BRONZE", "SILVER", "GOLD"].contains(tierStr) {
                    achievement["tier"] = tierStr
                }
            }

            if let iconIdx = iconUrlIndex, row.count > iconIdx, !row[iconIdx].isEmpty {
                achievement["iconUrl"] = row[iconIdx]
            }

            achievements.append(achievement)
        }

        guard !achievements.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "No valid achievements found in CSV"
            }
            return false
        }

        let mutation = """
        mutation BulkCreateAchievements($achievementSetId: ID!, $achievements: [BulkAchievementInput!]!) {
            bulkCreateAchievements(achievementSetId: $achievementSetId, achievements: $achievements) {
                success
                createdCount
                skippedCount
            }
        }
        """

        let variables: [String: Any] = [
            "achievementSetId": achievementSetId,
            "achievements": achievements
        ]

        do {
            let response: BulkCreateAchievementsResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            let result = response.bulkCreateAchievements
            DispatchQueue.main.async {
                self.importResult = result
                if result.success {
                    self.successMessage = "Imported \(result.createdCount) achievements (\(result.skippedCount) skipped)"
                    self.csvPreviewData = []
                } else {
                    self.errorMessage = "Import failed"
                }
            }
            if result.success {
                await fetchAchievements(setId: achievementSetId)
            }
            return result.success
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    func clearImportState() {
        DispatchQueue.main.async {
            self.csvPreviewData = []
            self.importResult = nil
        }
    }
}
