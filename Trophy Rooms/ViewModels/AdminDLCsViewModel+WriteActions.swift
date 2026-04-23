import Foundation

extension AdminDLCsViewModel {
    func createDLC(
        gameFamilyId: String,
        name: String,
        slug: String,
        type: DLCType,
        description: String?,
        coverUrl: String?,
        price: Double?,
        platformIds: [String]
    ) async -> Bool {
        await performDLCMutation(fallback: false) {
            let response = try await api.createDLC(
                gameFamilyId: gameFamilyId,
                name: name,
                slug: slug,
                type: type,
                description: description,
                coverUrl: coverUrl,
                price: price,
                platformIds: platformIds
            )
            if response.createDLC.success {
                await fetchDLCs(gameFamilyId: gameFamilyId)
                setSuccessMessage("DLC created successfully")
                return true
            }

            setErrorMessage("Failed to create DLC")
            return false
        }
    }

    func updateDLC(
        id: String,
        gameFamilyId: String,
        name: String,
        slug: String,
        type: DLCType,
        description: String?,
        coverUrl: String?,
        price: Double?,
        platformIds: [String]
    ) async -> Bool {
        await performDLCMutation(fallback: false) {
            let response = try await api.updateDLC(
                id: id,
                name: name,
                slug: slug,
                type: type,
                description: description,
                coverUrl: coverUrl,
                price: price,
                platformIds: platformIds
            )
            if response.updateDLC.success {
                await fetchDLCs(gameFamilyId: gameFamilyId)
                setSuccessMessage("DLC updated successfully")
                return true
            }

            setErrorMessage("Failed to update DLC")
            return false
        }
    }

    func deleteDLC(id: String, gameFamilyId: String) async -> Bool {
        await performDLCMutation(fallback: false) {
            let response = try await api.deleteDLC(id: id)
            if response.deleteDLC.success {
                DispatchQueue.main.async {
                    self.dlcs.removeAll { $0.id == id }
                    self.successMessage = "DLC deleted successfully"
                }
                return true
            }

            setErrorMessage("Failed to delete DLC")
            return false
        }
    }

    func bulkDeleteDLCs(ids: [String], gameFamilyId: String) async -> Int {
        await performDLCMutation(fallback: 0) {
            let response = try await api.bulkDeleteDLCs(ids: ids)
            if response.bulkDeleteDLCs.success {
                DispatchQueue.main.async {
                    self.dlcs.removeAll { ids.contains($0.id) }
                    self.successMessage = "Deleted \(response.bulkDeleteDLCs.deletedCount) DLC(s)"
                }
                return response.bulkDeleteDLCs.deletedCount
            }

            setErrorMessage("Failed to delete DLCs")
            return 0
        }
    }
}
