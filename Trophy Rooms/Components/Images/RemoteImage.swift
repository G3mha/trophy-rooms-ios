import SwiftUI
import Kingfisher

/// The one way the app loads a remote image. Kingfisher caches it in memory
/// and on disk, retries network failures, and starts a failed load again when
/// the view comes back on screen. A missing URL or a failed load shows
/// `fallback`; a load in progress shows the plain loading fill.
///
/// Size and clip it from outside (`.frame`, `.clipShape`): the fallback and
/// loading fill take the whole slot, and `contentMode` only applies to the
/// loaded image.
struct RemoteImage<Fallback: View>: View {
    let url: String?
    var contentMode: SwiftUI.ContentMode = .fill
    @ViewBuilder var fallback: () -> Fallback

    var body: some View {
        if let url = url.flatMap(URL.init(string:)) {
            KFImage(url)
                .placeholder { Rectangle().fill(CabinetLoadingView.fill) }
                .onFailureView(fallback)
                .retry(maxCount: 3, interval: .accumulated(2))
                .resizable()
                .contentConfigure { $0.aspectRatio(contentMode: contentMode) }
        } else {
            fallback()
        }
    }
}

extension RemoteImage where Fallback == ImagePlaceholder {
    /// Falls back to the standard grey slot with `icon` (none when nil).
    init(url: String?, contentMode: SwiftUI.ContentMode = .fill, icon: String? = "gamecontroller") {
        self.init(url: url, contentMode: contentMode) { ImagePlaceholder(icon: icon) }
    }
}

/// What an image slot shows with no URL or after a failed load. Set `.font`
/// from outside to size the icon.
struct ImagePlaceholder: View {
    var icon: String? = "gamecontroller"

    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(.gray)
                }
            }
    }
}

#Preview("No URL") {
    RemoteImage(url: nil)
        .frame(width: 60, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
}

#Preview("Bad host") {
    RemoteImage(url: "https://invalid.example/cover.jpg", icon: "puzzlepiece.extension")
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
}
