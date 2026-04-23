import Foundation

final class AdminAchievementSetsAPI {
    static let shared = AdminAchievementSetsAPI()

    let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }
}
