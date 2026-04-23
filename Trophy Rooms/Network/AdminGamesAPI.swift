import Foundation

final class AdminGamesAPI {
    static let shared = AdminGamesAPI()

    let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }
}
