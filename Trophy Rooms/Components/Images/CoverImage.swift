import SwiftUI

/// A reusable component for displaying game/DLC cover images with consistent styling
/// Uses CachedImageFixed internally for reliable loading and caching
struct CoverImage: View {
    let url: String?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let placeholderIcon: String

    init(
        url: String?,
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat = 8,
        placeholderIcon: String = "gamecontroller"
    ) {
        self.url = url
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.placeholderIcon = placeholderIcon
    }

    var body: some View {
        CachedImageFixed(
            url: url,
            width: width,
            height: height,
            cornerRadius: cornerRadius,
            placeholderIcon: placeholderIcon
        )
    }
}

// MARK: - Convenience Initializers

extension CoverImage {
    /// Standard game cover (60x80)
    static func gameRow(url: String?) -> CoverImage {
        CoverImage(url: url, width: 60, height: 80)
    }

    /// Small cover for lists (60x60)
    static func small(url: String?, icon: String = "gamecontroller") -> CoverImage {
        CoverImage(url: url, width: 60, height: 60, placeholderIcon: icon)
    }

    /// Medium cover for cards (100x133)
    static func medium(url: String?) -> CoverImage {
        CoverImage(url: url, width: 100, height: 133)
    }

    /// Large cover for detail views (150x200)
    static func large(url: String?) -> CoverImage {
        CoverImage(url: url, width: 150, height: 200, cornerRadius: 12)
    }

    /// DLC cover (60x60)
    static func dlc(url: String?) -> CoverImage {
        CoverImage(url: url, width: 60, height: 60, placeholderIcon: "puzzlepiece.extension")
    }
}

#Preview("Game Row") {
    CoverImage.gameRow(url: nil)
}

#Preview("Small") {
    CoverImage.small(url: nil)
}

#Preview("Medium") {
    CoverImage.medium(url: nil)
}

#Preview("Large") {
    CoverImage.large(url: nil)
}

#Preview("DLC") {
    CoverImage.dlc(url: nil)
}
