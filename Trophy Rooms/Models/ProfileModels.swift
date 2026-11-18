import Foundation

/// The lists a user can pin to their profile, ten games each
enum ShowcaseList: String, CaseIterable, Identifiable {
    case allTime = "ALL_TIME"
    case platinums = "PLATINUMS"
    case collection = "COLLECTION"

    static let maxGames = 10

    var id: String { rawValue }

    var title: String {
        switch self {
        case .allTime: return "Favorite Games of All Time"
        case .platinums: return "Top Platinums"
        case .collection: return "Collection Favorites"
        }
    }

    /// Shown in the picker when the user has nothing that fits the list
    var emptyCandidatesText: String {
        switch self {
        case .allTime: return "No games match that search."
        case .platinums: return "Earn a Platinum and it can go here."
        case .collection: return "Add games to your collection and they can go here."
        }
    }
}

/// Display order matches the web profile
enum SocialNetwork: String, CaseIterable, Identifiable {
    case psn = "PSN", xbox = "XBOX", nintendo = "NINTENDO", steam = "STEAM"
    case discord = "DISCORD", twitch = "TWITCH", youtube = "YOUTUBE", x = "X"
    case bluesky = "BLUESKY", instagram = "INSTAGRAM", tiktok = "TIKTOK"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .psn: return "PlayStation Network"
        case .xbox: return "Xbox"
        case .nintendo: return "Nintendo"
        case .steam: return "Steam"
        case .discord: return "Discord"
        case .twitch: return "Twitch"
        case .youtube: return "YouTube"
        case .x: return "X"
        case .bluesky: return "Bluesky"
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        }
    }

    var placeholder: String {
        switch self {
        case .psn: return "PSN ID"
        case .xbox: return "Gamertag"
        case .nintendo: return "SW-1234-5678-9012"
        case .steam: return "Custom URL name"
        case .discord, .twitch: return "Username"
        case .bluesky: return "name.bsky.social"
        case .youtube, .x, .instagram, .tiktok: return "@handle"
        }
    }
}

struct ProfileGame: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let slug: String
    let coverUrl: String?
}

struct SocialLink: Decodable, Identifiable {
    let id: String
    let network: String
    let handle: String
    /// Nil for networks with no public profile page (PSN, Xbox, Discord, Nintendo)
    let url: String?

    var label: String { SocialNetwork(rawValue: network)?.label ?? network }
}

/// Bio, picture, handles and pinned games, shared by the public profile and
/// the editor
struct ProfileDetails: Decodable {
    let bio: String?
    let avatarUrl: String?
    let socialLinks: [SocialLink]
    let allTime: [ProfileGame]
    let platinums: [ProfileGame]
    let collection: [ProfileGame]

    /// Selection set to embed in a User query
    static let fields = """
    bio
    avatarUrl
    socialLinks { id network handle url }
    allTime: showcase(list: ALL_TIME) { id title slug coverUrl }
    platinums: showcase(list: PLATINUMS) { id title slug coverUrl }
    collection: showcase(list: COLLECTION) { id title slug coverUrl }
    """

    func games(for list: ShowcaseList) -> [ProfileGame] {
        switch list {
        case .allTime: return allTime
        case .platinums: return platinums
        case .collection: return collection
        }
    }

    var sortedSocialLinks: [SocialLink] {
        let order = SocialNetwork.allCases.map(\.rawValue)
        return socialLinks.sorted {
            (order.firstIndex(of: $0.network) ?? order.count) < (order.firstIndex(of: $1.network) ?? order.count)
        }
    }
}
