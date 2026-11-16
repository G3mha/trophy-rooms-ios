import SwiftUI

struct ScreenshotGalleryView: View {
    let screenshots: [String]
    @State private var selectedIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Screenshots")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(screenshots.enumerated()), id: \.offset) { index, urlString in
                        // Tappable even after a failed load: the viewer loads it again
                        RemoteImage(url: urlString, icon: "photo")
                            .frame(width: 160, height: 90)
                            .cornerRadius(8)
                            .onTapGesture {
                                selectedIndex = index
                            }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedIndex.map { ScreenshotSelection(index: $0) } },
            set: { selectedIndex = $0?.index }
        )) { selection in
            FullScreenGalleryView(
                screenshots: screenshots,
                initialIndex: selection.index,
                onDismiss: { selectedIndex = nil }
            )
        }
    }
}

private struct ScreenshotSelection: Identifiable {
    let index: Int
    var id: Int { index }
}

struct FullScreenGalleryView: View {
    let screenshots: [String]
    let initialIndex: Int
    let onDismiss: () -> Void

    @State private var currentIndex: Int
    @GestureState private var dragOffset: CGFloat = 0

    init(screenshots: [String], initialIndex: Int, onDismiss: @escaping () -> Void) {
        self.screenshots = screenshots
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            TabView(selection: $currentIndex) {
                ForEach(Array(screenshots.enumerated()), id: \.offset) { index, urlString in
                    // A 16:9 slot (what IGDB screenshots are) so the loading
                    // fill doesn't cover the whole black page
                    RemoteImage(url: urlString, contentMode: .fit) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    }
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))

            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()

                Text("\(currentIndex + 1) / \(screenshots.count)")
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
            }
        }
    }
}
