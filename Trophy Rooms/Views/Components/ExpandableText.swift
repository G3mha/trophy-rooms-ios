//
//  ExpandableText.swift
//  Trophy Rooms
//
//  A reusable component that shows truncated text with "See more..."
//  and expands inline when tapped (similar to Instagram posts).
//

import SwiftUI

/// A view that displays text content with an expandable "See more..." feature.
///
/// When the content exceeds the specified line limit, it shows truncated text
/// with a "See more..." button. Tapping expands to show full content.
///
/// Example usage:
/// ```swift
/// ExpandableText(content: bundle.description, lineLimit: 4)
/// ```
struct ExpandableText: View {
    let content: String
    var lineLimit: Int = 4
    var font: Font = .body
    var foregroundColor: Color = .secondary

    @State private var isExpanded = false
    @State private var isTruncated = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Content with truncation detection - tappable to expand
            Text(content)
                .font(font)
                .foregroundStyle(foregroundColor)
                .lineLimit(isExpanded ? nil : lineLimit)
                .background(truncationDetector)
                .onTapGesture {
                    if isTruncated && !isExpanded {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isExpanded = true
                        }
                    }
                }

            // "See more..." indicator - only shown when truncated and not yet expanded
            if isTruncated && !isExpanded {
                Text("See more...")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .padding(.top, 4)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isExpanded = true
                        }
                    }
            }
        }
    }

    // MARK: - Truncation Detection

    /// Detects if content is truncated by comparing full vs limited height
    /// Uses the same width as the parent to ensure accurate measurement
    private var truncationDetector: some View {
        GeometryReader { geometry in
            // Measure both versions with the exact same width
            ZStack(alignment: .topLeading) {
                // Full height (no line limit)
                Text(content)
                    .font(font)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        GeometryReader { fullGeo in
                            Color.clear.onAppear {
                                checkTruncation(
                                    fullHeight: fullGeo.size.height,
                                    availableWidth: geometry.size.width
                                )
                            }
                            .onChange(of: fullGeo.size.height) { _, newHeight in
                                checkTruncation(
                                    fullHeight: newHeight,
                                    availableWidth: geometry.size.width
                                )
                            }
                        }
                    )

                // Truncated height (with line limit)
                Text(content)
                    .font(font)
                    .lineLimit(lineLimit)
                    .background(
                        GeometryReader { truncatedGeo in
                            Color.clear.onAppear {
                                checkTruncation(
                                    truncatedHeight: truncatedGeo.size.height,
                                    availableWidth: geometry.size.width
                                )
                            }
                            .onChange(of: truncatedGeo.size.height) { _, newHeight in
                                checkTruncation(
                                    truncatedHeight: newHeight,
                                    availableWidth: geometry.size.width
                                )
                            }
                        }
                    )
            }
            .frame(width: geometry.size.width)
            .hidden()
        }
    }

    // State for comparison
    @State private var fullHeight: CGFloat = 0
    @State private var truncatedHeight: CGFloat = 0

    private func checkTruncation(fullHeight: CGFloat? = nil, truncatedHeight: CGFloat? = nil, availableWidth: CGFloat) {
        if let full = fullHeight {
            self.fullHeight = full
        }
        if let truncated = truncatedHeight {
            self.truncatedHeight = truncated
        }

        // Only compare when both heights are measured
        if self.fullHeight > 0 && self.truncatedHeight > 0 {
            // Content is truncated if full height exceeds truncated height
            // Use threshold to account for minor floating point differences
            let newTruncated = self.fullHeight > self.truncatedHeight + 2
            if newTruncated != isTruncated {
                isTruncated = newTruncated
            }
        }
    }
}

#Preview("Short text (no truncation)") {
    ExpandableText(
        content: "This is a short description.",
        lineLimit: 4
    )
    .padding()
}

#Preview("Long text (with truncation)") {
    ExpandableText(
        content: """
        This is a much longer description that will definitely need to be truncated. \
        It contains multiple sentences and paragraphs worth of content that would \
        normally take up a lot of space on the screen. The user can tap "See more..." \
        to expand and read the full content. This pattern is commonly used in apps \
        like Instagram to show post captions without taking up too much vertical space.
        """,
        lineLimit: 4
    )
    .padding()
}
