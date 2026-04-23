import Foundation

final class AdminGameVersionsAPI {
    static let shared = AdminGameVersionsAPI()

    let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }
}
