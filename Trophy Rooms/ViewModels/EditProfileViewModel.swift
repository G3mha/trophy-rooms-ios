import Foundation
import Supabase
import UIKit

/// Loads and saves the signed-in user's profile. The picture saves on its
/// own; name, bio, handles and pinned games save together.
@MainActor
final class EditProfileViewModel: ObservableObject {
    static let nameMaxLength = 50
    static let bioMaxLength = 300
    private static let avatarSize: CGFloat = 512

    @Published var userId: String?
    @Published var name = ""
    @Published var bio = ""
    @Published var handles: [SocialNetwork: String] = [:]
    @Published var lists: [ShowcaseList: [ProfileGame]] = [:]
    @Published var candidates: [ShowcaseList: [ProfileGame]] = [:]
    @Published var avatarUrl: String?

    @Published var isLoading = true
    @Published var loadError: String?
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var saved = false
    @Published var avatarBusy = false
    @Published var avatarError: String?
    @Published private var savedSnapshot: Snapshot?

    /// What Save would send, to tell whether anything changed
    private struct Snapshot: Equatable {
        let name: String
        let bio: String
        let handles: [String]
        let lists: [[String]]
    }

    private var snapshot: Snapshot {
        Snapshot(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            handles: SocialNetwork.allCases.map { (handles[$0] ?? "").trimmingCharacters(in: .whitespaces) },
            lists: ShowcaseList.allCases.map { (lists[$0] ?? []).map(\.id) }
        )
    }

    var hasChanges: Bool {
        savedSnapshot.map { $0 != snapshot } ?? false
    }

    private struct MyProfile: Decodable {
        let id: String
        let name: String?
        let details: ProfileDetails

        private enum Keys: String, CodingKey { case id, name }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            details = try ProfileDetails(from: decoder)
        }
    }

    private struct LoadResponse: Decodable {
        let me: MyProfile?
        let platinums: [ProfileGame]
        let collection: [ProfileGame]
    }

    private struct ProfileResult: Decodable {
        let success: Bool
        let error: MutationError?
        let user: AvatarOnly?

        struct AvatarOnly: Decodable { let avatarUrl: String? }
    }

    func load() async {
        isLoading = true
        loadError = nil
        let query = """
        query EditProfile {
            me { id name \(ProfileDetails.fields) }
            platinums: myShowcaseCandidates(list: PLATINUMS) { id title slug coverUrl }
            collection: myShowcaseCandidates(list: COLLECTION) { id title slug coverUrl }
        }
        """
        do {
            let response: LoadResponse = try await NetworkService.shared.fetch(query: query)
            guard let me = response.me else {
                loadError = "Sign in to edit your profile."
                isLoading = false
                return
            }
            userId = me.id
            name = me.name ?? ""
            bio = me.details.bio ?? ""
            avatarUrl = me.details.avatarUrl
            handles = Dictionary(
                me.details.socialLinks.compactMap { link in
                    SocialNetwork(rawValue: link.network).map { ($0, link.handle) }
                },
                uniquingKeysWith: { first, _ in first }
            )
            lists = Dictionary(uniqueKeysWithValues: ShowcaseList.allCases.map { ($0, me.details.games(for: $0)) })
            candidates = [.platinums: response.platinums, .collection: response.collection]
            savedSnapshot = snapshot
        } catch is CancellationError {
            return
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    /// Catalog search for the all-time list, which takes any game. Uses the
    /// public global search: it keeps the ranking, and its GAME results are
    /// game families.
    func search(_ term: String) async -> [ProfileGame] {
        struct Response: Decodable {
            struct Item: Decodable {
                let id: String
                let type: String
                let title: String
                let coverUrl: String?
            }
            struct Results: Decodable { let items: [Item] }
            let globalSearch: Results
        }
        let query = """
        query SearchProfileGames($query: String!) {
            globalSearch(query: $query, limit: 25) { items { id type title coverUrl } }
        }
        """
        let response: Response? = try? await NetworkService.shared.fetch(query: query, variables: ["query": term])
        return (response?.globalSearch.items ?? [])
            .filter { $0.type == "GAME" }
            .map { ProfileGame(id: $0.id, title: $0.title, slug: "", coverUrl: $0.coverUrl) }
    }

    func save() async {
        isSaving = true
        saveError = nil
        saved = false
        // One request; GraphQL runs mutation fields in order
        let mutation = """
        mutation SaveProfile($input: UpdateMyProfileInput!, $allTime: [ID!]!, $platinums: [ID!]!, $collection: [ID!]!) {
            profile: updateMyProfile(input: $input) { success error { code message field } }
            allTime: setProfileShowcase(list: ALL_TIME, gameFamilyIds: $allTime) { success error { code message field } }
            platinums: setProfileShowcase(list: PLATINUMS, gameFamilyIds: $platinums) { success error { code message field } }
            collection: setProfileShowcase(list: COLLECTION, gameFamilyIds: $collection) { success error { code message field } }
        }
        """
        struct Response: Decodable {
            let profile: ProfileResult
            let allTime: ProfileResult
            let platinums: ProfileResult
            let collection: ProfileResult
        }
        let sent = snapshot
        let socialLinks = SocialNetwork.allCases.map { ["network": $0.rawValue, "handle": handles[$0] ?? ""] }
        let ids = { (list: ShowcaseList) in (self.lists[list] ?? []).map(\.id) }
        do {
            let response: Response = try await NetworkService.shared.fetch(query: mutation, variables: [
                "input": ["name": name, "bio": bio, "socialLinks": socialLinks],
                "allTime": ids(.allTime),
                "platinums": ids(.platinums),
                "collection": ids(.collection),
            ])
            let results: [(list: ShowcaseList?, result: ProfileResult)] = [
                (nil, response.profile),
                (.allTime, response.allTime),
                (.platinums, response.platinums),
                (.collection, response.collection),
            ]
            if let failure = results.first(where: { !$0.result.success }) {
                let message = failure.result.error?.message ?? "Something went wrong. Please try again."
                saveError = failure.list.map { "\($0.title): \(message)" } ?? message
            } else {
                savedSnapshot = sent
                saved = true
            }
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }

    func uploadAvatar(_ data: Data) async {
        avatarError = nil
        guard let supabaseId = AuthManager.shared.userId else { return }
        guard let image = UIImage(data: data), let jpeg = Self.avatarJPEG(image) else {
            avatarError = "Couldn't read that image."
            return
        }
        avatarBusy = true
        defer { avatarBusy = false }
        let path = "\(supabaseId)/\(UUID().uuidString.lowercased()).jpg"
        do {
            _ = try await AuthManager.shared.client.storage
                .from("avatars")
                .upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg"))
            try await setAvatarPath(path)
        } catch {
            avatarError = error.localizedDescription
        }
    }

    func removeAvatar() async {
        avatarError = nil
        avatarBusy = true
        defer { avatarBusy = false }
        do {
            try await setAvatarPath(nil)
        } catch {
            avatarError = error.localizedDescription
        }
    }

    private func setAvatarPath(_ path: String?) async throws {
        struct Response: Decodable { let updateMyProfile: ProfileResult }
        let mutation = """
        mutation SetAvatar($input: UpdateMyProfileInput!) {
            updateMyProfile(input: $input) { success error { code message field } user { avatarUrl } }
        }
        """
        let response: Response = try await NetworkService.shared.fetch(
            query: mutation,
            variables: ["input": ["avatarPath": path.map { $0 as Any } ?? NSNull()]]
        )
        let result = response.updateMyProfile
        guard result.success else {
            throw NSError(domain: "Profile", code: 0, userInfo: [
                NSLocalizedDescriptionKey: result.error?.message ?? "Couldn't update your picture.",
            ])
        }
        avatarUrl = result.user?.avatarUrl
    }

    /// Center-crops to a square and scales down so every picture is the same
    /// size and well under the bucket's 2 MB limit
    private static func avatarJPEG(_ image: UIImage) -> Data? {
        let side = min(image.size.width, image.size.height)
        guard side > 0 else { return nil }
        let target = min(side, avatarSize)
        let scale = target / side
        let drawn = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: target, height: target), format: format)
        return renderer.jpegData(withCompressionQuality: 0.85) { _ in
            image.draw(in: CGRect(
                x: (target - drawn.width) / 2,
                y: (target - drawn.height) / 2,
                width: drawn.width,
                height: drawn.height
            ))
        }
    }
}
