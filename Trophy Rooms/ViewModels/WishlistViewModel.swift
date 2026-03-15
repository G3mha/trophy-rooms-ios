import Foundation
import Combine

class WishlistViewModel: ObservableObject {
    @Published var wishlistItems: [WishlistItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchWishlist() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        let query = """
        query GetMyWishlist {
            myWishlist {
                id
                gameId
                gameTitle
                gameCoverUrl
                gameDescription
                achievementCount
                addedAt
            }
        }
        """

        do {
            let response: WishlistResponse = try await NetworkService.shared.fetch(query: query)
            DispatchQueue.main.async {
                self.wishlistItems = response.myWishlist
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func removeFromWishlist(gameId: String) async {
        let mutation = """
        mutation RemoveFromWishlist($gameId: ID!) {
            removeFromWishlist(gameId: $gameId) {
                success
            }
        }
        """

        do {
            let _: WishlistMutationResponse = try await NetworkService.shared.fetch(query: mutation, variables: ["gameId": gameId])
            DispatchQueue.main.async {
                self.wishlistItems.removeAll { $0.gameId == gameId }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
