import Foundation
import Combine

@MainActor
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

    func fetchGame(id: String, forceRefresh: Bool = false) async {
        // Load from cache immediately (no loading state)
        if !forceRefresh, let cached: GameDetailResponse = await CacheManager.shared.get(.game(id: id)) {
            game = cached.game
        }

        // Show loading only if no cached data
        if game == nil {
            isLoading = true
        }
        errorMessage = nil

        let query = """
        query GetGame($id: ID!) {
            game(id: $id) {
                id
                title
                description
                coverUrl
                type
                baseGames {
                    id
                    title
                    coverUrl
                    platform { id name slug }
                }
                derivedGames {
                    id
                    title
                    coverUrl
                    type
                    platform { id name slug }
                }
                derivedGameCount
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
                    gameFamilyCount
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
            await CacheManager.shared.set(.game(id: id), value: response)
            game = response.game
        } catch is CancellationError {
            // Cancelled - keep cached data
        } catch {
            // Only show error if no cached data
            if game == nil {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func toggleAchievement(_ achievement: Achievement) async {
        let achievementId = achievement.id
        let shouldMarkComplete = achievement.isCompleted != true
        let previousGame = game

        if let currentGame = game {
            game = currentGame.replacingAchievement(achievement.withCompletionState(shouldMarkComplete))
        }

        let mutationName = shouldMarkComplete ? "MarkAchievementComplete" : "UnmarkAchievementComplete"
        let mutationField = shouldMarkComplete ? "markAchievementComplete" : "unmarkAchievementComplete"

        let mutation = """
        mutation \(mutationName)($achievementId: ID!) {
            \(mutationField)(achievementId: $achievementId) {
                success
            }
        }
        """

        do {
            let _: SimpleMutationResponse = try await NetworkService.shared.fetch(query: mutation, variables: ["achievementId": achievementId])
        } catch {
            game = previousGame
            self.errorMessage = error.localizedDescription
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

        isBuylistLoading = true

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
                let response: BuylistItemIdResponse = try await NetworkService.shared.fetch(query: query)
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
                    await CacheInvalidation.forBuylistChange()
                    isInBuylist = false
                    isBuylistLoading = false
                } else {
                    isBuylistLoading = false
                }
            } catch {
                errorMessage = error.localizedDescription
                isBuylistLoading = false
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
                if response.addToBuylist.success {
                    await CacheInvalidation.forBuylistChange()
                    isInBuylist = true
                    buylistItemId = response.addToBuylist.buylistItem?.id
                }
                isBuylistLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isBuylistLoading = false
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

        isStatusLoading = true

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
            if response.setGameStatus.success {
                await CacheInvalidation.forLibraryChange()
                currentStatus = response.setGameStatus.status
                currentPlatformId = response.setGameStatus.platformId
                currentVersionId = response.setGameStatus.gameVersionId
            }
            isStatusLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isStatusLoading = false
        }
    }

    func clearGameStatus() async {
        guard let gameId = game?.id else { return }

        isStatusLoading = true

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
            if response.clearGameStatus.success {
                await CacheInvalidation.forLibraryChange()
                currentStatus = nil
                currentPlatformId = nil
                currentVersionId = nil
            }
            isStatusLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isStatusLoading = false
        }
    }

    // MARK: - Collection Methods

    func fetchCollectionForGame(gameId: String, forceRefresh: Bool = false) async {
        // Load from cache immediately
        if !forceRefresh, let cached: CollectionForGameResponse = await CacheManager.shared.get(.collectionForGame(gameId: gameId)) {
            collectionItems = cached.myCollectionForGame
        }

        if collectionItems.isEmpty {
            isCollectionLoading = true
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
            await CacheManager.shared.set(.collectionForGame(gameId: gameId), value: response)
            collectionItems = response.myCollectionForGame
        } catch {
            // Keep cached data on error
        }
        isCollectionLoading = false
    }

    // MARK: - DLC Ownership Methods

    func toggleDlcOwnership(dlcId: String) async {
        guard let dlc = game?.dlcs?.first(where: { $0.id == dlcId }) else { return }

        isDlcOwnershipLoading.insert(dlcId)

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
                // Invalidate game cache and refetch
                if let gameId = game?.id {
                    await CacheInvalidation.forGame(id: gameId)
                    await fetchGame(id: gameId, forceRefresh: true)
                }
            }

            isDlcOwnershipLoading.remove(dlcId)
        } catch {
            errorMessage = error.localizedDescription
            isDlcOwnershipLoading.remove(dlcId)
        }
    }
}
