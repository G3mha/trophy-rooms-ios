import SwiftUI

struct ProgressBar: View {
    let progress: Float
    var height: CGFloat = 8
    var backgroundColor: Color = Color(.systemGray5)
    var foregroundColor: Color = .blue
    /// What the bar is measuring, for VoiceOver. Without it the bar is a
    /// purely visual element and the completion it represents is unreadable.
    var label: String = "Progress"

    private var clamped: Float { min(max(progress, 0), 1) }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(backgroundColor)
                    .cornerRadius(height / 2)

                Rectangle()
                    .fill(foregroundColor)
                    .frame(width: geometry.size.width * CGFloat(clamped))
                    .cornerRadius(height / 2)
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue("\(Int((clamped * 100).rounded()))%")
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
