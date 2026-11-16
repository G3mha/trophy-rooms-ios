import SwiftUI

/// A remote image in a fixed-ratio slot that takes the width it is given
/// (grid cells). Loading, retry and the fallback live in `RemoteImage`.
struct CachedImage: View {
    let url: String?
    let aspectRatio: CGFloat
    let cornerRadius: CGFloat
    let placeholderIcon: String
    let contentMode: SwiftUI.ContentMode

    init(
        url: String?,
        aspectRatio: CGFloat = 3/4,
        cornerRadius: CGFloat = 8,
        placeholderIcon: String = "gamecontroller",
        contentMode: SwiftUI.ContentMode = .fill
    ) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        self.placeholderIcon = placeholderIcon
        self.contentMode = contentMode
    }

    var body: some View {
        // The slot sets the size and the image fills it, so art that isn't
        // exactly this ratio is cropped instead of stretched
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                RemoteImage(url: url, contentMode: contentMode, icon: placeholderIcon)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            // Clipping hides the cropped overflow but doesn't stop it taking taps
            .contentShape(Rectangle())
    }
}

// MARK: - Fixed Size Variant

/// A remote image with fixed dimensions (for row layouts)
struct CachedImageFixed: View {
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
        RemoteImage(url: url, icon: placeholderIcon)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension CachedImageFixed {
    /// Standard game cover for rows (60x80)
    static func gameRow(url: String?) -> CachedImageFixed {
        CachedImageFixed(url: url, width: 60, height: 80)
    }

    /// DLC cover (60x60)
    static func dlc(url: String?) -> CachedImageFixed {
        CachedImageFixed(url: url, width: 60, height: 60, placeholderIcon: "puzzlepiece.extension")
    }
}

// MARK: - Previews

#Preview("Game Cover") {
    CachedImage(url: nil)
        .frame(width: 120)
}

#Preview("Game Row") {
    CachedImageFixed.gameRow(url: nil)
}

#Preview("DLC") {
    CachedImageFixed.dlc(url: nil)
}
