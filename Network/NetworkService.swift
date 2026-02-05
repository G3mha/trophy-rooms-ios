import Foundation
import Clerk

class NetworkService {
    static let shared = NetworkService()

    private let url: URL

    private init() {
        if let configuredUrl = Bundle.main.object(forInfoDictionaryKey: "GRAPHQL_URL") as? String,
           let parsedUrl = URL(string: configuredUrl) {
            self.url = parsedUrl
        } else {
            self.url = URL(string: "http://localhost:4000/graphql")!
        }
    }

    func fetch<T: Decodable>(query: String, variables: [String: Any] = [:]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let session = Clerk.shared.session {
            if let token = try await session.getToken()?.jwt {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        let body: [String: Any] = [
            "query": query,
            "variables": variables
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        let response = try JSONDecoder().decode(GraphQLResponse<T>.self, from: data)
        if let errors = response.errors, let first = errors.first {
            throw NSError(domain: "GraphQL", code: 0, userInfo: [NSLocalizedDescriptionKey: first.message])
        }

        guard let data = response.data else {
            throw NSError(domain: "GraphQL", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data returned"])
        }

        return data
    }
}

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Decodable {
    let message: String
}
