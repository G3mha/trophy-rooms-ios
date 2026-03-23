import Foundation
import Combine

class GameDetailViewModel: ObservableObject {
    @Published var game: GameDetail?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isInBuylist = false
    @Published var isBuylistLoading = false
    @Published var buylistItemId: String?
    @Published var currentStatus: GameStatus?
    @Published var currentPlatformId: String?
    @Published var currentVersionId: String?
    @Published var isStatusLoading = false
    @Published var collectionItems: [CollectionItem] = []
    @Published var isCollectionLoading = false
    @Published var ownedDlcIds: Set<String> = []
    @Published var isDlcOwnershipLoading: Set<String> = []

    func fetchGame(id: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetGame($id: ID!) {
            game(id: $id) {
                id
                title
                description
                coverUrl
                type
                baseGameId
                baseGame {
                    id
                    title
                    coverUrl
                    platform { id name slug }
                }
                derivatives {
                    id
                    title
                    coverUrl
                    type
                    platform { id name slug }
                }
                derivativeCount
                trophyCount
                releaseDate
                developer
                publisher
                genre
                esrbRating
                screenshots
                platform { id name slug }
                versions {
                    id
                    name
                    slug
                    description
                    coverUrl
                    effectiveCoverUrl
                    isDefault
                    gameId
                    dlcs {
                        id
                        name
                        slug
                        type
                    }
                    dlcCount
                }
                versionCount
                defaultVersion {
                    id
                    name
                    slug
                    description
                    coverUrl
                    effectiveCoverUrl
                    isDefault
                    gameId
                    dlcs {
                        id
                        name
                        slug
                        type
                    }
                    dlcCount
                }
                dlcs {
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
                    achievementSetCount
                }
                dlcCount
                bundles {
                    id
                    name
                    slug
                    type
                    description
                    coverUrl
                    gameCount
                    dlcCount
                }
                achievementSets {
                    id
                    title
                    type
                    visibility
                    createdByUserId
                    gameVersionId
                    gameVersion {
                        id
                        name
                    }
                    dlcId
                    dlc {
                        id
                        name
                        type
                    }
                    achievements {
                        id
                        title
                        description
                        iconUrl
                        points
                        tier
                        isCompleted
                        userCount
                        achievementSetId
                    }
                }
            }
        }
        """

        do {
            let response: GameDetailResponse = try await NetworkService.shared.fetch(query: query, variables: ["id": id])
            DispatchQueue.main.async {
                self.game = response.game
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func toggleAchievement(_ achievement: Achievement) async {
        let achievementId = achievement.id

        let mutationName = achievement.isCompleted == true ? "UnmarkAchievementComplete" : "MarkAchievementComplete"
        let mutationField = achievement.isCompleted == true ? "unmarkAchievementComplete" : "markAchievementComplete"

        let mutation = """
        mutation \(mutationName)($achievementId: ID!) {
            \(mutationField)(achievementId: $achievementId) {
                success
            }
        }
        """

        do {
            let _: SimpleMutationResponse = try await NetworkService.shared.fetch(query: mutation, variables: ["achievementId": achievementId])
            if let gameId = game?.id {
                await fetchGame(id: gameId)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func checkBuylist(gameId: String) async {
        let query = """
        query IsInBuylist($gameId: ID) {
            isInBuylist(gameId: $gameId)
        }
        """

        do {
            let response: IsInBuylistResponse = try await NetworkService.shared.fetch(query: query, variables: ["gameId": gameId])
            DispatchQueue.main.async {
                self.isInBuylist = response.isInBuylist
            }
        } catch {
            // Silently fail - user might not be logged in
        }
    }

    func toggleBuylist() async {
        guard let gameId = game?.id else { return }

        DispatchQueue.main.async {
            self.isBuylistLoading = true
        }

        if isInBuylist {
            // Remove from buylist - we need to find the item ID first
            let query = """
            query GetMyBuylist {
                myBuylist {
                    id
                    gameId
                }
            }
            """

            do {
                let response: BuylistResponse = try await NetworkService.shared.fetch(query: query)
                if let item = response.myBuylist.first(where: { $0.gameId == gameId }) {
                    let mutation = """
                    mutation RemoveFromBuylist($id: ID!) {
                        removeFromBuylist(id: $id) {
                            success
                        }
                    }
                    """
                    let _: RemoveFromBuylistResponse = try await NetworkService.shared.fetch(
                        query: mutation,
                        variables: ["id": item.id]
                    )
                    DispatchQueue.main.async {
                        self.isInBuylist = false
                        self.isBuylistLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isBuylistLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isBuylistLoading = false
                }
            }
        } else {
            // Add to buylist
            let mutation = """
            mutation AddToBuylist($input: AddToBuylistInput!) {
                addToBuylist(input: $input) {
                    success
                    buylistItem {
                        id
                    }
                }
            }
            """

            let input: [String: Any] = [
                "gameId": gameId,
                "priority": "MEDIUM"
            ]

            do {
                let response: AddToBuylistResponse = try await NetworkService.shared.fetch(
                    query: mutation,
                    variables: ["input": input]
                )
                DispatchQueue.main.async {
                    if response.addToBuylist.success {
                        self.isInBuylist = true
                        self.buylistItemId = response.addToBuylist.buylistItem?.id
                    }
                    self.isBuylistLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isBuylistLoading = false
                }
            }
        }
    }

    // MARK: - Game Status Methods

    func checkGameStatus(gameId: String) async {
        let query = """
        query GetGameStatus($gameId: ID!) {
            getGameStatus(gameId: $gameId) {
                status
                platformId
                gameVersionId
            }
        }
        """

        do {
            let response: GameStatusResponse = try await NetworkService.shared.fetch(query: query, variables: ["gameId": gameId])
            DispatchQueue.main.async {
                self.currentStatus = response.getGameStatus?.status
                self.currentPlatformId = response.getGameStatus?.platformId
                self.currentVersionId = response.getGameStatus?.gameVersionId
            }
        } catch {
            // Silently fail - user might not be logged in
        }
    }

    func setGameStatus(_ status: GameStatus, platformId: String? = nil, gameVersionId: String? = nil) async {
        guard let gameId = game?.id else { return }

        DispatchQueue.main.async {
            self.isStatusLoading = true
        }

        let mutation = """
        mutation SetGameStatus($gameId: ID!, $status: GameStatus!, $platformId: ID, $gameVersionId: ID) {
            setGameStatus(gameId: $gameId, status: $status, platformId: $platformId, gameVersionId: $gameVersionId) {
                success
                status
                platformId
                gameVersionId
            }
        }
        """

        var variables: [String: Any] = ["gameId": gameId, "status": status.rawValue]
        if let platformId = platformId {
            variables["platformId"] = platformId
        }
        if let gameVersionId = gameVersionId {
            variables["gameVersionId"] = gameVersionId
        }

        do {
            let response: SetGameStatusResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: variables
            )
            DispatchQueue.main.async {
                if response.setGameStatus.success {
                    self.currentStatus = response.setGameStatus.status
                    self.currentPlatformId = response.setGameStatus.platformId
                    self.currentVersionId = response.setGameStatus.gameVersionId
                }
                self.isStatusLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isStatusLoading = false
            }
        }
    }

    func clearGameStatus() async {
        guard let gameId = game?.id else { return }

        DispatchQueue.main.async {
            self.isStatusLoading = true
        }

        let mutation = """
        mutation ClearGameStatus($gameId: ID!) {
            clearGameStatus(gameId: $gameId) {
                success
            }
        }
        """

        do {
            let response: ClearGameStatusResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["gameId": gameId]
            )
            DispatchQueue.main.async {
                if response.clearGameStatus.success {
                    self.currentStatus = nil
                    self.currentPlatformId = nil
                    self.currentVersionId = nil
                }
                self.isStatusLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isStatusLoading = false
            }
        }
    }

    // MARK: - Collection Methods

    func fetchCollectionForGame(gameId: String) async {
        DispatchQueue.main.async {
            self.isCollectionLoading = true
        }

        let query = """
        query GetMyCollectionForGame($gameId: ID!) {
            myCollectionForGame(gameId: $gameId) {
                id
                gameId
                game { id title coverUrl }
                platform { id name slug }
                gameVersion { id name }
                gameVersionId
                hasDisc
                hasBox
                hasManual
                hasExtras
                isSealed
                region
                notes
                createdAt
                updatedAt
            }
        }
        """

        do {
            let response: CollectionForGameResponse = try await NetworkService.shared.fetch(
                query: query,
                variables: ["gameId": gameId]
            )
            DispatchQueue.main.async {
                self.collectionItems = response.myCollectionForGame
                self.isCollectionLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isCollectionLoading = false
            }
        }
    }

    // MARK: - DLC Ownership Methods

    func toggleDlcOwnership(dlcId: String) async {
        guard let dlc = game?.dlcs?.first(where: { $0.id == dlcId }) else { return }

        DispatchQueue.main.async {
            self.isDlcOwnershipLoading.insert(dlcId)
        }

        let isCurrentlyOwned = dlc.isOwned ?? false
        let mutationName = isCurrentlyOwned ? "RemoveDLCFromOwned" : "AddDLCToOwned"
        let mutationField = isCurrentlyOwned ? "removeDLCFromOwned" : "addDLCToOwned"

        let mutation = """
        mutation \(mutationName)($dlcId: ID!) {
            \(mutationField)(dlcId: $dlcId) {
                success
            }
        }
        """

        do {
            let response: DLCOwnershipMutationResponse = try await NetworkService.shared.fetch(
                query: mutation,
                variables: ["dlcId": dlcId]
            )

            let success = isCurrentlyOwned
                ? response.removeDLCFromOwned?.success ?? false
                : response.addDLCToOwned?.success ?? false

            if success {
                // Refetch game to get updated ownership state
                if let gameId = game?.id {
                    await fetchGame(id: gameId)
                }
            }

            DispatchQueue.main.async {
                self.isDlcOwnershipLoading.remove(dlcId)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isDlcOwnershipLoading.remove(dlcId)
            }
        }
    }
}
