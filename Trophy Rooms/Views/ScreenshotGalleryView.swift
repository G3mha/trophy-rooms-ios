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
                        if let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 160, height: 90)
                                        .cornerRadius(8)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 160, height: 90)
                                        .clipped()
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            selectedIndex = index
                                        }
                                case .failure:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 160, height: 90)
                                        .cornerRadius(8)
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
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
                    if let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .tag(index)
                    }
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
