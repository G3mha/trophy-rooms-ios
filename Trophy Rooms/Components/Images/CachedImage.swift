import SwiftUI
import Kingfisher

/// A reusable cached image component using Kingfisher for reliable loading and caching
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
        if let urlString = url, let imageUrl = URL(string: urlString) {
            KFImage(imageUrl)
                .placeholder {
                    placeholder
                        .overlay {
                            ProgressView()
                                .tint(.secondary)
                        }
                }
                .retry(maxCount: 3, interval: .seconds(2))
                .onFailure { _ in }
                .resizable()
                .aspectRatio(aspectRatio, contentMode: contentMode)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                Image(systemName: placeholderIcon)
                    .foregroundStyle(.gray)
            }
    }
}

// MARK: - Fixed Size Variant

/// A cached image with fixed dimensions (for row layouts)
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
        if let urlString = url, let imageUrl = URL(string: urlString) {
            KFImage(imageUrl)
                .placeholder {
                    placeholder
                        .overlay {
                            ProgressView()
                                .tint(.secondary)
                        }
                }
                .retry(maxCount: 3, interval: .seconds(2))
                .onFailure { _ in }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .frame(width: width, height: height)
            .overlay {
                Image(systemName: placeholderIcon)
                    .foregroundStyle(.gray)
            }
    }
}

// MARK: - Convenience Factory Methods

extension CachedImage {
    /// Standard game cover for grids (3:4 aspect ratio)
    static func gameCover(url: String?, cornerRadius: CGFloat = 8) -> CachedImage {
        CachedImage(url: url, aspectRatio: 3/4, cornerRadius: cornerRadius)
    }

    /// Square cover (1:1 aspect ratio)
    static func square(url: String?, icon: String = "gamecontroller") -> CachedImage {
        CachedImage(url: url, aspectRatio: 1, placeholderIcon: icon)
    }

    /// DLC cover (1:1 aspect ratio with puzzle icon)
    static func dlc(url: String?) -> CachedImage {
        CachedImage(url: url, aspectRatio: 1, placeholderIcon: "puzzlepiece.extension")
    }

    /// Bundle cover (1:1 aspect ratio with stack icon)
    static func bundle(url: String?) -> CachedImage {
        CachedImage(url: url, aspectRatio: 1, placeholderIcon: "square.stack.3d.up")
    }
}

extension CachedImageFixed {
    /// Standard game cover for rows (60x80)
    static func gameRow(url: String?) -> CachedImageFixed {
        CachedImageFixed(url: url, width: 60, height: 80)
    }

    /// Small cover for lists (60x60)
    static func small(url: String?, icon: String = "gamecontroller") -> CachedImageFixed {
        CachedImageFixed(url: url, width: 60, height: 60, placeholderIcon: icon)
    }

    /// Medium cover for cards (100x133)
    static func medium(url: String?) -> CachedImageFixed {
        CachedImageFixed(url: url, width: 100, height: 133)
    }

    /// Large cover for detail views (150x200)
    static func large(url: String?) -> CachedImageFixed {
        CachedImageFixed(url: url, width: 150, height: 200, cornerRadius: 12)
    }

    /// DLC cover (60x60)
    static func dlc(url: String?) -> CachedImageFixed {
        CachedImageFixed(url: url, width: 60, height: 60, placeholderIcon: "puzzlepiece.extension")
    }
}

// MARK: - Previews

#Preview("Game Cover") {
    CachedImage.gameCover(url: nil)
        .frame(width: 120)
}

#Preview("Game Row") {
    CachedImageFixed.gameRow(url: nil)
}

#Preview("Small") {
    CachedImageFixed.small(url: nil)
}

#Preview("Medium") {
    CachedImageFixed.medium(url: nil)
}

#Preview("Large") {
    CachedImageFixed.large(url: nil)
}

#Preview("DLC") {
    CachedImage.dlc(url: nil)
        .frame(width: 60)
}
