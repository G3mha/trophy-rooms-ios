import Foundation

final class AdminPlatformsAPI {
    static let shared = AdminPlatformsAPI()

    let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }
}
