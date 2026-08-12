import SwiftUI

/// Zero state for the collection-style tabs.
///
/// Uses the backlit trophy shelf as its emblem in place of a grey SF Symbol,
/// so an empty room looks like an empty cabinet rather than a missing asset.
struct CabinetEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            TrophyShelfView()

            Text(title)
                .font(.headline)
                .foregroundStyle(Cabinet.bone)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CabinetEmptyState(
        title: "Your Library Is Empty",
        message: "Browse games and add them to your library"
    )
    .background(Cabinet.canvas)
}
