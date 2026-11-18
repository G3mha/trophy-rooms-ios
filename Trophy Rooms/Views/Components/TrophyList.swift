import SwiftUI

// The trophy list pieces the game and DLC screens share: the filter, the
// controls above a list, one folding list, and the trophy row itself.

extension Array where Element == Achievement {
    // The backend awards the Platinum, so progress counts never include it
    var withoutPlatinum: [Achievement] {
        filter { $0.tier != .PLATINUM }
    }
}

extension Array where Element == AchievementSet {
    var hasTrophyDescriptions: Bool {
        contains { $0.achievements.contains { !($0.description ?? "").isEmpty } }
    }
}

enum TrophyFilter: String, CaseIterable {
    case all = "All"
    case notEarned = "Not earned"
    case earned = "Earned"

    func shows(_ achievement: Achievement) -> Bool {
        switch self {
        case .all: return true
        case .notEarned: return achievement.isCompleted != true
        case .earned: return achievement.isCompleted == true
        }
    }

    var emptyText: String {
        self == .earned ? "Nothing earned yet." : "All earned."
    }
}

extension View {
    // The cabinet card a trophy section sits in
    func trophyCard() -> some View {
        padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Cabinet.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Cabinet.brass.opacity(0.20), lineWidth: 1)
            )
    }
}

// The filter (only a signed-in player has anything earned to filter by) and
// the switch that reveals every description at once
struct TrophyControls: View {
    let showsFilter: Bool
    @Binding var filter: TrophyFilter
    let showsReveal: Bool
    @Binding var revealsDescriptions: Bool

    var body: some View {
        if showsFilter || showsReveal {
            VStack(alignment: .trailing, spacing: 6) {
                if showsFilter {
                    Picker("Show", selection: $filter) {
                        ForEach(TrophyFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if showsReveal {
                    Button {
                        Motion.animate(.easeInOut(duration: 0.2)) { revealsDescriptions.toggle() }
                    } label: {
                        Label(
                            revealsDescriptions ? "Hide descriptions" : "Show descriptions",
                            systemImage: revealsDescriptions ? "eye.slash" : "eye"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

// One trophy list, folded behind its name and count
struct TrophyListView: View {
    let achievementSet: AchievementSet
    let filter: TrophyFilter
    let revealsDescriptions: Bool
    let isAuthenticated: Bool
    let onToggle: (Achievement) -> Void
    @State private var isExpanded: Bool

    init(
        achievementSet: AchievementSet,
        filter: TrophyFilter,
        revealsDescriptions: Bool,
        isAuthenticated: Bool,
        startsExpanded: Bool = false,
        onToggle: @escaping (Achievement) -> Void
    ) {
        self.achievementSet = achievementSet
        self.filter = filter
        self.revealsDescriptions = revealsDescriptions
        self.isAuthenticated = isAuthenticated
        self.onToggle = onToggle
        _isExpanded = State(initialValue: startsExpanded)
    }

    private var counted: [Achievement] {
        achievementSet.achievements.withoutPlatinum
    }

    private var countText: String {
        if isAuthenticated {
            return "\(counted.filter { $0.isCompleted == true }.count) of \(counted.count)"
        }
        return counted.count == 1 ? "1 trophy" : "\(counted.count) trophies"
    }

    private var visible: [Achievement] {
        achievementSet.achievements.filter(filter.shows)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            Button {
                Motion.animate(.easeInOut(duration: 0.24)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))

                    Text(achievementSet.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    Text(countText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(isExpanded ? "Hides the trophies" : "Shows the trophies")

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if achievementSet.achievements.isEmpty {
                        Text("No trophies in this list yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else if visible.isEmpty {
                        Text(filter.emptyText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(visible) { achievement in
                            AchievementRow(
                                achievement: achievement,
                                tracksProgress: isAuthenticated,
                                // The backend awards the Platinum, so it shows without a tick
                                canToggle: isAuthenticated && achievement.tier != .PLATINUM,
                                revealsDescription: revealsDescriptions,
                                onToggle: { onToggle(achievement) }
                            )
                        }
                    }
                }
                // Plain fade: a move transition slides ghost rows across
                // neighboring content while the container resizes
                .transition(.opacity)
            }
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    // Signed in, so earned and not yet earned look different
    let tracksProgress: Bool
    let canToggle: Bool
    // Shows the description without the per-trophy reveal
    let revealsDescription: Bool
    let onToggle: () -> Void

    // Descriptions can spoil the game, so each one stays hidden until asked for
    @State private var showsDescription = false

    private var hasDescription: Bool {
        !(achievement.description ?? "").isEmpty
    }

    private var isCompleted: Bool {
        achievement.isCompleted == true
    }

    private var isLocked: Bool {
        tracksProgress && !isCompleted
    }

    private var tier: AchievementTier {
        achievement.tier ?? .BRONZE
    }

    var body: some View {
        HStack(spacing: 10) {
            if canToggle {
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .strokeBorder(isCompleted ? Cabinet.brass : Color.secondary, lineWidth: 2)
                        if isCompleted {
                            Circle()
                                .fill(Cabinet.brass)
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Cabinet.ink)
                        }
                    }
                    .frame(width: 24, height: 24)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isCompleted ? "Mark as not earned" : "Mark as earned")
                .accessibilityValue(achievement.title)
                .accessibilityAddTraits(isCompleted ? [.isSelected] : [])
            }

            TrophyIcon(url: achievement.iconUrl, tier: tier, isLocked: isLocked)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(achievement.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isLocked ? Color.secondary : Color.primary)
                        // The ring's colour carries the tier on screen
                        .accessibilityLabel("\(achievement.title), \(tier.accessibilityLabel)")

                    if hasDescription && !revealsDescription {
                        Button {
                            Motion.animate(.easeInOut(duration: 0.2)) { showsDescription.toggle() }
                        } label: {
                            Image(systemName: showsDescription ? "eye.slash" : "eye")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(showsDescription ? "Hide description" : "Show description")
                        .accessibilityValue(achievement.title)
                    }
                }

                if revealsDescription || showsDescription, let description = achievement.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let earnedPercent = achievement.earnedPercent {
                    Text("\(earnedPercent.formatted(.number.precision(.fractionLength(0...1))))% of players")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.leading, canToggle ? 0 : 10)
        .padding(.trailing, 12)
        .frame(minHeight: 60)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    tracksProgress && isCompleted ? Cabinet.brass.opacity(0.45) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
    }
}

// The tier shows as a metal ring around the icon. A trophy not earned yet
// goes grey inside it, and the ring keeps its metal.
private struct TrophyIcon: View {
    let url: String?
    let tier: AchievementTier
    let isLocked: Bool

    var body: some View {
        RemoteImage(url: url) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 16))
                .foregroundStyle(tier.tierColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Cabinet.ink)
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .grayscale(isLocked ? 1 : 0)
        .brightness(isLocked ? -0.25 : 0)
        .padding(3)
        .background(Circle().fill(tier.tierColor))
        .accessibilityHidden(true)
    }
}
