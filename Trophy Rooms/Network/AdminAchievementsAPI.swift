import Foundation

final class AdminAchievementsAPI {
    static let shared = AdminAchievementsAPI()

    let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }
}
