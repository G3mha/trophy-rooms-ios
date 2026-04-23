import Foundation

extension AdminAchievementsViewModel {
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
            setErrorMessage("No data to import (need header + at least one row)")
            return false
        }

        DispatchQueue.main.async {
            self.errorMessage = nil
            self.successMessage = nil
            self.importResult = nil
        }

        let headers = csvPreviewData[0].map { $0.lowercased() }
        let dataRows = Array(csvPreviewData.dropFirst())

        let titleIndex = headers.firstIndex(of: "title") ?? headers.firstIndex(of: "name")
        let descriptionIndex = headers.firstIndex(of: "description") ?? headers.firstIndex(of: "desc")
        let pointsIndex = headers.firstIndex(of: "points") ?? headers.firstIndex(of: "point")
        let tierIndex = headers.firstIndex(of: "tier")
        let iconUrlIndex = headers.firstIndex(of: "iconurl") ?? headers.firstIndex(of: "icon_url") ?? headers.firstIndex(of: "icon")

        guard let titleIdx = titleIndex else {
            setErrorMessage("CSV must have a 'title' or 'name' column")
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
                achievement["points"] = 10
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
            setErrorMessage("No valid achievements found in CSV")
            return false
        }

        do {
            let response = try await api.bulkCreateAchievements(
                achievementSetId: achievementSetId,
                achievements: achievements
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
            setErrorMessage(error.localizedDescription)
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
