import SwiftUI

/// Badge for displaying platform with optional icon
struct PlatformTypeBadge: View {
    let name: String
    let slug: String?

    init(name: String, slug: String? = nil) {
        self.name = name
        self.slug = slug
    }

    var body: some View {
        TypeBadge(
            name,
            icon: "gamecontroller",
            color: .secondary
        )
    }
}

/// Badge for displaying game version
struct GameVersionBadge: View {
    let name: String

    var body: some View {
        TypeBadge(
            name,
            icon: "square.stack.3d.up",
            color: .indigo
        )
    }
}

#Preview("Platform Badges") {
    VStack(spacing: 8) {
        PlatformTypeBadge(name: "PlayStation 5", slug: "ps5")
        PlatformTypeBadge(name: "Xbox Series X", slug: "xbox-series-x")
        PlatformTypeBadge(name: "Nintendo Switch")
    }
    .padding()
}

#Preview("Version Badges") {
    VStack(spacing: 8) {
        GameVersionBadge(name: "PC")
        GameVersionBadge(name: "Remastered")
        GameVersionBadge(name: "Director's Cut")
    }
    .padding()
}
