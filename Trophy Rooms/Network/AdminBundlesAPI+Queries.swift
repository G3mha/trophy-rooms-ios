import Foundation

extension AdminBundlesAPI {
    func fetchBundles(type: BundleType?) async throws -> BundlesResponse {
        let query = """
        query GetBundles($type: BundleType) {
            bundles(type: $type) {
                id
                name
                slug
                type
                description
                coverUrl
                releaseDate
                price
                platform {
                    id
                    name
                    slug
                }
                platformId
                gameFamilyCount
                dlcCount
                gameFamilies {
                    id
                    title
                }
                dlcs {
                    id
                    name
                    gameFamily {
                        id
                        title
                        coverUrl
                    }
                }
            }
        }
        """

        var variables: [String: Any] = [:]
        if let type {
            variables["type"] = type.rawValue
        }

        return try await networkService.fetch(query: query, variables: variables)
    }

    func fetchAvailableDLCs() async throws -> AllDLCsResponse {
        let query = """
        query GetAllDLCs {
            allDlcs {
                id
                name
                type
                coverUrl
                gameFamily {
                    id
                    title
                    coverUrl
                }
            }
        }
        """

        return try await networkService.fetch(query: query)
    }
}
