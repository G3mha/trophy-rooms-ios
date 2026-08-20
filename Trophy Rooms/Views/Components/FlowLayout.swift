import SwiftUI

// MARK: - Flow Layout

/// A layout that arranges views in a flowing manner, wrapping to new lines as needed
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint], sizes: [CGSize]) {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let maxContainerWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if currentX + size.width > maxContainerWidth && currentX > 0 {
                // Move to next line
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX - spacing)
        }

        return (
            size: CGSize(width: maxWidth, height: currentY + lineHeight),
            positions: positions,
            sizes: sizes
        )
    }
}

#Preview("Platform Selection Field") {
    struct PreviewWrapper: View {
        @State var selectedIds: Set<String> = ["1", "2"]

        var body: some View {
            Form {
                Section("Platforms") {
                    PlatformSelectionField(
                        platforms: [
                            Platform(id: "1", name: "Nintendo Switch", slug: "switch"),
                            Platform(id: "2", name: "PlayStation 5", slug: "ps5"),
                            Platform(id: "3", name: "Xbox Series X", slug: "xbox-series-x"),
                            Platform(id: "4", name: "PC", slug: "pc"),
                        ],
                        selectedPlatformIds: $selectedIds
                    )
                }
            }
        }
    }

    return PreviewWrapper()
}
