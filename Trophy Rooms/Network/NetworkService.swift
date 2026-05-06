import Foundation
import ClerkKit

class NetworkService {
    static let shared = NetworkService()

    private let url: URL

    private init() {
        if let configuredUrl = Bundle.main.object(forInfoDictionaryKey: "GRAPHQL_URL") as? String,
           let parsedUrl = URL(string: configuredUrl) {
            self.url = parsedUrl
        } else {
            self.url = URL(string: "https://api.trophyrooms.org/graphql")!
        }
    }

    func fetch<T: Decodable>(query: String, variables: [String: Any] = [:]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Set auth token with timeout to prevent hanging
        if let session = Clerk.shared.session {
            do {
                let token = try await withTimeout(seconds: 5) {
                    try await session.getToken()
                }
                if let token = token {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
            } catch {
                // If token fetch fails or times out, continue without auth
                print("NetworkService: Token fetch failed or timed out: \(error)")
            }
        }

        let body: [String: Any] = [
            "query": query,
            "variables": variables
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30 // 30 second timeout

        let (responseData, _) = try await URLSession.shared.data(for: request)

        // Debug: print raw response
        #if DEBUG
        if let jsonString = String(data: responseData, encoding: .utf8) {
            print("NetworkService: Raw response (first 2000 chars): \(String(jsonString.prefix(2000)))")
        }
        #endif

        do {
            let response = try JSONDecoder().decode(GraphQLResponse<T>.self, from: responseData)
            if let data = response.data {
                #if DEBUG
                if let errors = response.errors, !errors.isEmpty {
                    let messages = errors.map { $0.message }.joined(separator: " | ")
                    print("NetworkService: GraphQL returned partial data with errors: \(messages)")
                }
                #endif
                return data
            }

            if let errors = response.errors, let first = errors.first {
                throw NSError(domain: "GraphQL", code: 0, userInfo: [NSLocalizedDescriptionKey: first.message])
            }

            guard let data = response.data else {
                throw NSError(domain: "GraphQL", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data returned"])
            }

            return data
        } catch let decodingError as DecodingError {
            // Provide detailed decoding error information
            let errorMessage: String
            switch decodingError {
            case .keyNotFound(let key, let context):
                errorMessage = "Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .typeMismatch(let type, let context):
                errorMessage = "Type mismatch for '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let type, let context):
                errorMessage = "Value not found for '\(type)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .dataCorrupted(let context):
                errorMessage = "Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            @unknown default:
                errorMessage = decodingError.localizedDescription
            }
            print("NetworkService: Decoding error - \(errorMessage)")
            throw NSError(domain: "Decoding", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }
}

struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLError]?
}

struct GraphQLError: Decodable {
    let message: String
}

// Helper to add timeout to async operations
func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw NSError(domain: "Timeout", code: -1, userInfo: [NSLocalizedDescriptionKey: "Operation timed out"])
        }

        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
