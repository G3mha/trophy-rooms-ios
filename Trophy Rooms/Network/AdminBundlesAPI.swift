import Foundation

final class AdminBundlesAPI {
    static let shared = AdminBundlesAPI()

    let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }
}
