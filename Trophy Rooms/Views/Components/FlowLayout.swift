import SwiftUI

// MARK: - Flow Layout

/// A layout that arranges views in a row, wrapping to the next line as needed.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let width = wrapWidth(for: proposal, sizes: sizes)
        let result = computeLayout(maxWidth: width, sizes: sizes)
        // Never claim more width than we were offered. Reporting the full
        // single-line width lets an enclosing VStack adopt it, after which
        // nothing wraps and every sibling overflows with us.
        return CGSize(width: min(result.size.width, width), height: result.size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        // Wrap against the width actually granted, not the proposal.
        let result = computeLayout(maxWidth: bounds.width, sizes: sizes)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    /// The width to wrap against.
    ///
    /// SwiftUI measures with an unspecified width during its ideal-size pass.
    /// Treating that as infinite lays everything on one line and reports a
    /// runaway ideal width, so fall back to the widest single item instead -
    /// the narrowest width at which this layout can still fit its content.
    private func wrapWidth(for proposal: ProposedViewSize, sizes: [CGSize]) -> CGFloat {
        if let width = proposal.width, width > 0, width.isFinite {
            return width
        }
        return sizes.map(\.width).max() ?? 0
    }

    private func computeLayout(
        maxWidth: CGFloat,
        sizes: [CGSize]
    ) -> (size: CGSize, positions: [CGPoint], sizes: [CGSize]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for size in sizes {
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            usedWidth = max(usedWidth, currentX - spacing)
        }

        return (
            size: CGSize(width: usedWidth, height: currentY + lineHeight),
            positions: positions,
            sizes: sizes
        )
    }
}
