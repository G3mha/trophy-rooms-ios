import SwiftUI
import Kingfisher

struct PlatformIcon: View {
    let slug: String
    let size: CGFloat

    // Base URL for platform icons (from deployed web app)
    private let baseURL = "https://trophyrooms.org/platforms"

    init(slug: String, size: CGFloat = 16) {
        self.slug = slug
        self.size = size
    }

    var body: some View {
        KFImage(URL(string: "\(baseURL)/\(slug).png"))
            .placeholder {
                // Show fallback SF Symbol while loading
                Image(systemName: sfSymbol(for: slug))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .foregroundColor(.secondary)
            }
            .onFailure { _ in }
            .retry(maxCount: 2, interval: .seconds(1))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }

    // Map platform slugs to appropriate SF Symbols
    private func sfSymbol(for slug: String) -> String {
        switch slug {
        // Nintendo
        case "switch", "switch-2", "wii", "wii-u", "gamecube", "n64", "snes", "nes":
            return "gamecontroller.fill"
        case "3ds", "nds", "gba", "game-boy-color", "game-boy":
            return "rectangle.portrait.fill"

        // PlayStation
        case "ps5", "ps4", "ps3", "ps2", "ps1":
            return "playstation.logo"
        case "psp", "vita":
            return "rectangle.portrait.fill"

        // Xbox
        case "xbox-series", "xbox-one", "xbox-360", "xbox":
            return "xbox.logo"

        // PC
        case "pc", "windows":
            return "desktopcomputer"
        case "macos":
            return "laptopcomputer"
        case "linux":
            return "terminal.fill"
        case "steam", "epic", "gog":
            return "desktopcomputer"

        // Mobile
        case "android":
            return "apps.iphone"
        case "ios":
            return "iphone"

        // Sega
        case "genesis", "saturn", "dreamcast", "game-gear", "master-system":
            return "gamecontroller.fill"

        // Other
        default:
            return "gamecontroller.fill"
        }
    }
}

// Convenience view that shows icon + name
struct PlatformBadgeWithIcon: View {
    let slug: String
    let name: String
    let showName: Bool
    let iconSize: CGFloat

    init(slug: String, name: String, showName: Bool = true, iconSize: CGFloat = 14) {
        self.slug = slug
        self.name = name
        self.showName = showName
        self.iconSize = iconSize
    }

    var body: some View {
        HStack(spacing: 4) {
            PlatformIcon(slug: slug, size: iconSize)
            if showName {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.15))
        .foregroundColor(.secondary)
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 16) {
        PlatformIcon(slug: "switch", size: 24)
        PlatformIcon(slug: "ps5", size: 24)
        PlatformIcon(slug: "xbox-series", size: 24)
        PlatformIcon(slug: "pc", size: 24)

        PlatformBadgeWithIcon(slug: "switch", name: "Nintendo Switch")
        PlatformBadgeWithIcon(slug: "ps5", name: "PlayStation 5")
    }
    .padding()
}
