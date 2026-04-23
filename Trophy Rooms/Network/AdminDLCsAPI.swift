import Foundation

final class AdminDLCsAPI {
    static let shared = AdminDLCsAPI()

    let networkService: NetworkService

    init(networkService: NetworkService = .shared) {
        self.networkService = networkService
    }
}
