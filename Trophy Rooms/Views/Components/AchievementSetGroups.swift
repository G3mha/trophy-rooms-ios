import SwiftUI

// Groups sets by what a player needs to know: does the set gate the trophy,
// is it a bonus list, or is it their own private checklist. Shared by the game
// and DLC screens, which each bring their own row.
struct AchievementSetGroups<Item: TrophyRoleSet & Identifiable, Row: View>: View {
    let sets: [Item]
    @ViewBuilder let row: (Item) -> Row

    var body: some View {
        group("For the Trophy", sets: sets.filter(\.gatesTrophy))
        group(
            "Extra Lists",
            note: "These don't count toward the trophy.",
            sets: sets.filter { !$0.gatesTrophy && !$0.isPrivateCustom }
        )
        group("Your Lists", sets: sets.filter(\.isPrivateCustom))
    }

    @ViewBuilder
    private func group(_ title: String, note: String? = nil, sets: [Item]) -> some View {
        if !sets.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                if let note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(sets) { set in
                    row(set)
                }
            }
        }
    }
}
