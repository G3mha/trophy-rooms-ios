import SwiftUI

/// A profile picture, falling back to initials on a brass disc
struct ProfileAvatar: View {
    let url: String?
    let name: String?
    let userId: String
    var size: CGFloat = 80

    var body: some View {
        RemoteImage(url: url) {
            ZStack {
                Circle().fill(Cabinet.brass)
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .bold))
                    .foregroundColor(Cabinet.ink)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
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
}

/// Bio and social handles under a profile's name
struct ProfileAbout: View {
    let profile: ProfileDetails

    var body: some View {
        VStack(spacing: 10) {
            if let bio = profile.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            if !profile.socialLinks.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(profile.sortedSocialLinks) { link in
                        SocialChip(link: link)
                    }
                }
            }
        }
    }
}

private struct SocialChip: View {
    let link: SocialLink

    var body: some View {
        let label = HStack(spacing: 4) {
            Text(link.label).foregroundColor(.secondary)
            Text(link.handle).foregroundColor(.primary)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .overlay(Capsule().stroke(Color.secondary.opacity(0.35)))

        if let url = link.url.flatMap(URL.init(string:)) {
            Link(destination: url) { label }
                .accessibilityLabel("\(link.label): \(link.handle)")
        } else {
            label
                .accessibilityElement(children: .combine)
        }
    }
}

/// The lists a user pinned to their profile; empty lists are left out
struct ProfileShowcases: View {
    let profile: ProfileDetails

    var body: some View {
        ForEach(ShowcaseList.allCases) { list in
            let games = profile.games(for: list)
            if !games.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(list.title.uppercased())
                        .font(Cabinet.display(18))
                        .foregroundColor(Cabinet.bone)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                                NavigationLink(destination: GameFamilyRouter(title: game.title)) {
                                    ShowcaseCover(game: game, rank: index + 1)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct ShowcaseCover: View {
    let game: ProfileGame
    let rank: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RemoteImage(url: game.coverUrl) {
                Cabinet.card.overlay(Image(systemName: "gamecontroller").foregroundColor(.secondary))
            }
            .frame(width: 96, height: 128)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(alignment: .topLeading) {
                Text("\(rank)")
                    .font(Cabinet.display(13))
                    .foregroundColor(Cabinet.ink)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Cabinet.brass, in: RoundedRectangle(cornerRadius: 3))
                    .padding(5)
            }
            Text(game.title)
                .font(.caption)
                .lineLimit(2)
                .frame(width: 96, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Number \(rank): \(game.title)")
    }
}
