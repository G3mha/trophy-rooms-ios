import SwiftUI

struct ProgressBar: View {
    let progress: Float
    var height: CGFloat = 8
    var backgroundColor: Color = Color(.systemGray5)
    var foregroundColor: Color = .blue

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(backgroundColor)
                    .cornerRadius(height / 2)

                Rectangle()
                    .fill(foregroundColor)
                    .frame(width: geometry.size.width * CGFloat(min(max(progress, 0), 1)))
                    .cornerRadius(height / 2)
            }
        }
        .frame(height: height)
    }
}

struct ProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProgressBar(progress: 0.25)
            ProgressBar(progress: 0.5, foregroundColor: .green)
            ProgressBar(progress: 0.75, foregroundColor: .orange)
            ProgressBar(progress: 1.0, foregroundColor: .purple)
        }
        .padding()
    }
}
