import SwiftUI

struct UserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    let userId: String
    let userName: String?

    var body: some View {
        Group {
            if viewModel.isLoading {
                CabinetLoadingView("Loading profile...", layout: .detail)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task {
                            await viewModel.fetchUserProfile(userId: userId)
                        }
                    }
                }
            } else if let user = viewModel.user {
                ScrollView {
                    VStack(spacing: 20) {
                        ProfileNameplate(user: user)

                        ProfileShowcases(profile: user.profile)

                        // Recent achievements
                        if !viewModel.recentAchievements.isEmpty {
                            RecentAchievementsSection(achievements: viewModel.recentAchievements)
                        }
                    }
                    .padding()
                }
            } else {
                Text("User not found")
            }
        }
        .navigationTitle(userName ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchUserProfile(userId: userId)
        }
    }
}

/// Who the player is and their numbers, on one walnut panel
private struct ProfileNameplate: View {
    let user: PublicUserWithAchievements

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    ProfileAvatar(url: user.avatarUrl, name: user.name, userId: user.id, size: 84, framed: true)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(playerDisplayName(user.name, id: user.id).uppercased())
                            .font(Cabinet.display(30))
                            .foregroundColor(Cabinet.bone)
                            .shadow(color: Cabinet.shadowRed.opacity(0.85), radius: 0, x: 3, y: 3)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .accessibilityAddTraits(.isHeader)
                        if let memberSince {
                            Text("Member since \(memberSince)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                ProfileAbout(profile: user.profile)
            }
            .padding(20)

            ProfileLedger(user: user)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .walnutPanel()
    }

    private var memberSince: String? {
        guard let createdAt = user.createdAt else { return nil }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = parser.date(from: createdAt) ?? {
            parser.formatOptions = [.withInternetDateTime]
            return parser.date(from: createdAt)
        }()
        return date?.formatted(.dateTime.month(.wide).year())
    }
}

/// The nameplate's bottom rail: headline numbers and trophies by tier
private struct ProfileLedger: View {
    let user: PublicUserWithAchievements

    private var tiers: [(tier: AchievementTier, count: Int)] {
        guard let stats = user.stats else { return [] }
        return [
            (.PLATINUM, stats.platinumCount),
            (.GOLD, stats.goldCount),
            (.SILVER, stats.silverCount),
            (.BRONZE, stats.bronzeCount),
        ]
    }

    var body: some View {
        let total = tiers.reduce(0) { $0 + $1.count }

        VStack(alignment: .leading, spacing: 18) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 16) {
                GridRow {
                    LedgerStat(value: "\(user.trophyCount)", label: "Platinums")
                    LedgerStat(value: "\(user.achievementCount)", label: "Trophies")
                }
                GridRow {
                    LedgerStat(value: "\(user.gamesWithAchievementsCount)", label: "Games")
                    if let stats = user.stats {
                        LedgerStat(value: "\(Int(stats.completionRate.rounded()))%", label: "Completion")
                    }
                }
            }

            if total > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    GeometryReader { geometry in
                        let shown = tiers.filter { $0.count > 0 }
                        let width = geometry.size.width - CGFloat(shown.count - 1) * 2
                        HStack(spacing: 2) {
                            ForEach(shown, id: \.tier) { item in
                                Rectangle()
                                    .fill(item.tier.tierColor)
                                    .frame(width: max(3, width * CGFloat(item.count) / CGFloat(total)))
                            }
                        }
                    }
                    .frame(height: 8)
                    .background(Cabinet.bone.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .accessibilityHidden(true)

                    FlowLayout(spacing: 14) {
                        ForEach(tiers, id: \.tier) { item in
                            HStack(spacing: 5) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(item.tier.tierColor)
                                    .frame(width: 8, height: 8)
                                Text(item.tier.rawValue.capitalized)
                                    .foregroundColor(.secondary)
                                Text("\(item.count)")
                                    .fontWeight(.semibold)
                            }
                            .font(.footnote)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Cabinet.ink.opacity(0.38))
        .overlay(alignment: .top) {
            Rectangle().fill(Cabinet.brass.opacity(0.3)).frame(height: 1)
        }
    }
}

private struct LedgerStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(Cabinet.display(26))
                .foregroundColor(Cabinet.bone)
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}

private struct RecentAchievementsSection: View {
    let achievements: [UserAchievementItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Trophies")
                .font(.headline)

            ForEach(achievements) { achievement in
                RecentAchievementRow(item: achievement)
            }
        }
    }
}

private struct RecentAchievementRow: View {
    let item: UserAchievementItem

    var body: some View {
        HStack(spacing: 12) {
            // Achievement icon
            RemoteImage(url: item.achievement.iconUrl, contentMode: .fit) {
                tierColor.opacity(0.3)
                    .overlay(
                        Image(systemName: "trophy.fill")
                            .foregroundColor(tierColor)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.achievement.title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if let tier = item.achievement.tier {
                        TierBadge(tier: tier)
                    }
                }

                Text(item.achievement.achievementSet.gameFamily.title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formattedDate(item.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Cabinet.card)
        .cornerRadius(12)
    }

    var tierColor: Color {
        guard let tier = item.achievement.tier else { return .gray }
        switch tier {
        case .PLATINUM: return Color(red: 0.898, green: 0.894, blue: 0.886)
        case .GOLD: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .SILVER: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .BRONZE: return Color(red: 0.8, green: 0.5, blue: 0.2)
        }
    }

    func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        return dateString
    }
}
