import Foundation
import Combine

class DLCDetailViewModel: ObservableObject {
    @Published var dlc: DLCDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOwnershipLoading = false
    @Published var toggleError: String?

    func fetchDLC(id: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetDLC($id: ID!) {
            dlc(id: $id) {
                id
                name
                slug
                type
                description
                coverUrl
                effectiveCoverUrl
                releaseDate
                price
                isOwned
                gameFamily {
                    id
                    title
                    slug
                    coverUrl
                }
                achievementSets {
                    id
                    title
                    type
                    visibility
                    countsTowardTrophy
                    achievements {
                        id
                        title
                        description
                        iconUrl
                        tier
                        isCompleted
                        earnedPercent
                        achievementSetId
                    }
                }
                bundles {
                    id
                    name
                    type
                    coverUrl
                }
            }
        }
        """

        do {
            let response: DLCDetailResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["id": id]
            )
            DispatchQueue.main.async {
                self.dlc = response.dlc
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    // A tick shows at once and is put back if the server refuses it
    @MainActor
    func toggleAchievement(_ achievement: Achievement) async {
        let earned = achievement.isCompleted != true
        dlc = dlc?.replacingAchievement(achievement.withCompletionState(earned))
        do {
            if let refusal = try await TrophyTick.send(achievementId: achievement.id, earned: earned) {
                dlc = dlc?.replacingAchievement(achievement)
                toggleError = refusal
            }
        } catch {
            dlc = dlc?.replacingAchievement(achievement)
            toggleError = error.localizedDescription
        }
    }

    func addOwnership() async {
        guard let dlcId = dlc?.id else { return }

        DispatchQueue.main.async {
            self.isOwnershipLoading = true
        }

        let mutation = """
        mutation AddDLCToOwned($dlcId: ID!) {
            addDLCToOwned(dlcId: $dlcId) {
                success
            }
        }
        """

        do {
            let response: DLCOwnershipMutationResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["dlcId": dlcId]
            )

            if response.addDLCToOwned?.success == true {
                await fetchDLC(id: dlcId)
            }

            DispatchQueue.main.async {
                self.isOwnershipLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isOwnershipLoading = false
            }
        }
    }

    func removeOwnership() async {
        guard let dlcId = dlc?.id else { return }

        DispatchQueue.main.async {
            self.isOwnershipLoading = true
        }

        let mutation = """
        mutation RemoveDLCFromOwned($dlcId: ID!) {
            removeDLCFromOwned(dlcId: $dlcId) {
                success
            }
        }
        """

        do {
            let response: DLCOwnershipMutationResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["dlcId": dlcId]
            )

            if response.removeDLCFromOwned?.success == true {
                await fetchDLC(id: dlcId)
            }

            DispatchQueue.main.async {
                self.isOwnershipLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isOwnershipLoading = false
            }
        }
    }

    func toggleOwnership() async {
        let isCurrentlyOwned = dlc?.isOwned ?? false

        if isCurrentlyOwned {
            await removeOwnership()
        } else {
            await addOwnership()
        }
    }
}
