import SwiftUI

/// The app's loading state: a pulsing skeleton shaped like the content on its
/// way. The message is what VoiceOver reads.
///
/// Fills the available space on purpose: a view that sizes to its own content
/// makes any canvas behind it shrink to a small patch and leaves the rest of
/// the screen black.
struct CabinetLoadingView: View {
    enum Layout {
        /// Cover thumbnail and two lines per row: lists, feeds, search
        case rows
        /// Cover grid: games, library, collection, buylist
        case grid
        /// Large cover over a block of text: detail pages and profiles
        case detail
    }

    static let fill = Color(.tertiarySystemFill)

    let message: String
    let layout: Layout

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    init(_ message: String, layout: Layout = .rows) {
        self.message = message
        self.layout = layout
    }

    var body: some View {
        Group {
            switch layout {
            case .rows: rows
            case .grid: grid
            case .detail: detail
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
        .opacity(pulsing ? 0.5 : 1)
        .cabinetAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulsing)
        // Never start the pulse under Reduce Motion: the animation is nil
        // there, so flipping `pulsing` would dim the skeleton to 50% and
        // leave it there rather than resting at full opacity.
        .onAppear { pulsing = !reduceMotion }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
    }

    private var rows: some View {
        VStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { _ in
                HStack(spacing: 12) {
                    bone(width: 48, height: 64, radius: 6)
                    VStack(alignment: .leading, spacing: 6) {
                        bone(width: 180, height: 14)
                        bone(width: 120, height: 10)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(
                    Cabinet.card,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: GameCoverGridLayout.columns(), spacing: 12) {
            ForEach(0..<12, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Self.fill)
                    .aspectRatio(3 / 4, contentMode: .fit)
            }
        }
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 12) {
            bone(width: 160, height: 213, radius: 12)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            bone(width: 220, height: 22)
            bone(width: 160, height: 12)
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Self.fill)
                    .frame(height: 12)
            }
        }
    }

    private func bone(width: CGFloat, height: CGFloat, radius: CGFloat = 4) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Self.fill)
            .frame(width: width, height: height)
    }
}

#Preview("Rows") {
    CabinetLoadingView("Loading activity...")
        .background(Cabinet.canvas)
}

#Preview("Grid") {
    CabinetLoadingView("Loading library...", layout: .grid)
        .background(Cabinet.canvas)
}

#Preview("Detail") {
    CabinetLoadingView("Loading bundle...", layout: .detail)
        .background(Cabinet.canvas)
}
