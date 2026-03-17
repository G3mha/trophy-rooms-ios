import SwiftUI

struct ActivityView: View {
    @StateObject private var viewModel = ActivityViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(ActivityFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading activity...")
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                    Spacer()
                } else if viewModel.activities.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No activity yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Be the first to earn an achievement!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List(viewModel.activities) { activity in
                        NavigationLink(destination: UserProfileView(userId: activity.userId, userName: activity.userName)) {
                            ActivityEntryRow(activity: activity)
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Activity")
        .onChange(of: viewModel.selectedFilter) {
            viewModel.applyFilter()
        }
        .task {
            await viewModel.fetchActivity()
        }
    }
}

private struct ActivityEntryRow: View {
    let activity: ActivityEntry

    var icon: String {
        activity.type == "TROPHY" ? "trophy.fill" : "star.fill"
    }

    var iconColor: Color {
        if activity.type == "TROPHY" {
            return Color(red: 0.863, green: 0.078, blue: 0.235) // Crimson
        }
        if let tier = activity.achievementTier {
            switch tier {
            case .GOLD: return Color(red: 1.0, green: 0.843, blue: 0.0)
            case .SILVER: return Color(red: 0.753, green: 0.753, blue: 0.753)
            case .BRONZE: return Color(red: 0.804, green: 0.498, blue: 0.196)
            }
        }
        return .yellow
    }

    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: activity.earnedAt) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: activity.earnedAt) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }

        return activity.earnedAt
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.userName ?? activity.userEmail)
                        .font(.headline)
                    Spacer()
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if activity.type == "TROPHY" {
                    HStack(spacing: 6) {
                        Text("Earned a trophy in \(activity.gameTitle)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if let platformSlug = activity.platformSlug, let platformName = activity.platformName {
                            PlatformBadgeWithIcon(slug: platformSlug, name: platformName)
                        } else if let platformName = activity.platformName {
                            PlatformBadge(name: platformName)
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        Text(activity.achievementTitle ?? "Achievement")
                            .font(.subheadline)
                        if let tier = activity.achievementTier {
                            TierBadge(tier: tier)
                        }
                    }
                    HStack(spacing: 6) {
                        Text(activity.gameTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let platformSlug = activity.platformSlug, let platformName = activity.platformName {
                            PlatformBadgeWithIcon(slug: platformSlug, name: platformName)
                        } else if let platformName = activity.platformName {
                            PlatformBadge(name: platformName)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
