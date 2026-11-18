import SwiftUI

/// A profile picture, falling back to initials on the same tint the website
/// gives that player. `framed` adds the brass ring and hard shadow used on
/// the profile and its editor.
struct ProfileAvatar: View {
    let url: String?
    let name: String?
    let userId: String
    var size: CGFloat = 80
    var framed = false

    var body: some View {
        RemoteImage(url: url) {
            ZStack {
                Circle().fill(Self.tint(name: name, userId: userId))
                Text(initials)
                    .font(Cabinet.display(size * 0.36))
                    .foregroundColor(Cabinet.ink)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            if framed {
                Circle().strokeBorder(Cabinet.brass, lineWidth: 3)
            }
        }
        .background {
            if framed {
                Circle().fill(Cabinet.ink).offset(x: 4, y: 4)
            }
        }
        .accessibilityHidden(true)
    }

    private var initials: String {
        if let name, !name.isEmpty {
            let parts = name.split(separator: " ")
            if parts.count >= 2 {
                return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
            }
            return String(name.prefix(2)).uppercased()
        }
        return String(userId.suffix(2)).uppercased()
    }

    private static let tints = [
        Cabinet.brass,
        Cabinet.Tint.info,
        Cabinet.Tint.violet,
        Cabinet.Tint.amber,
        Cabinet.Tint.positive,
        Cabinet.Tint.warm,
        Cabinet.Tint.muted,
    ]

    /// The web's getAvatarColor (src/components/ProfileHeader.tsx), step for
    /// step with JavaScript's number rules, so a player's initials have the
    /// same colour on both. `<<` truncates to Int32 but the subtraction
    /// doesn't, so the running value stays a Double between steps.
    static func tint(name: String?, userId: String) -> Color {
        let seed = (name?.isEmpty == false ? name! : userId)
        var hash: Double = 0
        for unit in seed.utf16 {
            let shifted = Int32(truncatingIfNeeded: Int64(hash)) << 5
            hash = Double(unit) + (Double(shifted) - hash)
        }
        let index = Int(abs(hash).truncatingRemainder(dividingBy: Double(tints.count)))
        return tints[index]
    }
}

/// Bio and social handles under a profile's name
struct ProfileAbout: View {
    let profile: ProfileDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !profile.socialLinks.isEmpty {
                FlowLayout(spacing: 16) {
                    ForEach(profile.sortedSocialLinks) { link in
                        SocialHandle(link: link)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SocialHandle: View {
    let link: SocialLink

    var body: some View {
        let url = link.url.flatMap(URL.init(string:))
        let label = HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(link.label.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.2)
                .foregroundColor(Cabinet.brass)
            Text(link.handle)
                .font(.subheadline)
                .foregroundColor(.primary)
                .underline(url != nil, color: Cabinet.brass.opacity(0.5))
        }

        if let url {
            Link(destination: url) { label }
                .accessibilityLabel("\(link.label): \(link.handle)")
        } else {
            label
                .accessibilityElement(children: .combine)
        }
    }
}

/// Engraved brass nameplate for a section title
struct CabinetPlaque: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(Cabinet.display(12))
            .tracking(2)
            .foregroundColor(Color(red: 0.227, green: 0.165, blue: 0.071)) // #3a2a12
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.890, green: 0.773, blue: 0.510), location: 0), // #e3c582
                        .init(color: Cabinet.brass, location: 0.45),
                        .init(color: Cabinet.brassDeep, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(Color(red: 0.290, green: 0.204, blue: 0.094), lineWidth: 2) // #4a3418
            )
            .background(RoundedRectangle(cornerRadius: 3).fill(Cabinet.ink).offset(x: 3, y: 3))
            .accessibilityAddTraits(.isHeader)
    }
}

/// Walnut panel lit from above, the backdrop of the profile's cabinet pieces
struct WalnutPanel: View {
    var spotlight: UnitPoint? = UnitPoint(x: 0.25, y: 0)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Cabinet.walnutDeep,
                    Color(red: 0.200, green: 0.125, blue: 0.059), // #33200f
                    Color(red: 0.165, green: 0.102, blue: 0.047), // #2a1a0c
                    Cabinet.walnutDeep,
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            if let spotlight {
                RadialGradient(
                    colors: [Cabinet.amber.opacity(0.13), .clear],
                    center: spotlight,
                    startRadius: 0,
                    endRadius: 320
                )
            }
        }
    }
}

extension View {
    /// Rounded walnut panel with a thin brass edge
    func walnutPanel(spotlight: UnitPoint? = UnitPoint(x: 0.25, y: 0)) -> some View {
        background(WalnutPanel(spotlight: spotlight))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Cabinet.brass.opacity(0.28), lineWidth: 1))
    }
}

/// The lists a user pinned to their profile, one cabinet shelf each; empty
/// lists are left out
struct ProfileShowcases: View {
    let profile: ProfileDetails

    var body: some View {
        let lists = ShowcaseList.allCases.filter { !profile.games(for: $0).isEmpty }
        if !lists.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(lists.enumerated()), id: \.element.id) { index, list in
                    if index > 0 {
                        Rectangle()
                            .fill(Color(red: 0.086, green: 0.051, blue: 0.024)) // #160d06
                            .frame(height: 8)
                    }
                    ShowcaseShelf(list: list, games: profile.games(for: list))
                }
            }
            .walnutPanel(spotlight: nil)
        }
    }
}

private struct ShowcaseShelf: View {
    let list: ShowcaseList
    let games: [ProfileGame]

    static let coverWidth: CGFloat = 92
    static let coverHeight: CGFloat = 123
    private static let shelfTop: CGFloat = 16
    private static let shelfThickness: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CabinetPlaque(text: list.title)
                .padding(.leading, 16)
                .padding(.top, 18)

            // The shelf edge doesn't scroll: it's the same all the way along,
            // so it's drawn once behind the scrolling covers
            ZStack(alignment: .topLeading) {
                ShelfEdge()
                    .frame(height: Self.shelfThickness)
                    .padding(.top, Self.shelfTop + Self.coverHeight)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 14) {
                        ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                            NavigationLink(destination: GameFamilyRouter(title: game.title)) {
                                ShowcaseCover(game: game, rank: index + 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, Self.shelfTop)
                    .padding(.bottom, 16)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RadialGradient(colors: [Cabinet.amber.opacity(0.12), .clear], center: .top, startRadius: 0, endRadius: 260)
        )
    }
}

/// The lit front edge of a shelf
private struct ShelfEdge: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(red: 0.910, green: 0.835, blue: 0.675), location: 0),    // #e8d5ac
                .init(color: Color(red: 0.690, green: 0.553, blue: 0.329), location: 0.22), // #b08d54
                .init(color: Color(red: 0.361, green: 0.247, blue: 0.133), location: 0.6),  // #5c3f22
                .init(color: Color(red: 0.110, green: 0.067, blue: 0.031), location: 1),    // #1c1108
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct ShowcaseCover: View {
    let game: ProfileGame
    let rank: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RemoteImage(url: game.coverUrl) {
                Cabinet.card.overlay(Image(systemName: "gamecontroller").foregroundColor(.secondary))
            }
            .frame(width: ShowcaseShelf.coverWidth, height: ShowcaseShelf.coverHeight)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .background(Rectangle().fill(Cabinet.ink.opacity(0.55)).offset(x: 4))

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(rank)")
                    .font(Cabinet.display(14))
                    .foregroundColor(Cabinet.brass)
                Text(game.title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(width: ShowcaseShelf.coverWidth, alignment: .leading)
            .padding(.top, 20)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Number \(rank): \(game.title)")
    }
}
