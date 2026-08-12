import SwiftUI

/// Backlit trophy silhouettes on a shelf - the cabinet identity's signature
/// motif (see .claude/skills/trophy-cabinet-design). Use on empty and
/// signed-out states.
struct TrophyShelfView: View {
    var body: some View {
        // The trophies must drive the layout height. Putting the glow in the
        // background rather than as a ZStack sibling stops the 190pt gradient
        // from sizing the view - otherwise the silhouettes overflow the frame
        // and collide with whatever follows them.
        HStack(alignment: .bottom, spacing: 26) {
            TrophySilhouette(kind: .cup)
                .frame(width: 58, height: 100)
            TrophySilhouette(kind: .star)
                .frame(width: 36, height: 70)
            TrophySilhouette(kind: .medal)
                .frame(width: 44, height: 53)
            TrophySilhouette(kind: .obelisk)
                .frame(width: 34, height: 63)
            TrophySilhouette(kind: .cup)
                .frame(width: 48, height: 83)
        }
        .foregroundStyle(Cabinet.ink)
        .background(alignment: .bottom) {
            // An elliptical gradient is fully transparent at its own boundary,
            // so no frame edge can ever expose a cut line - the pool of light
            // simply dissolves into the canvas on all sides
            EllipticalGradient(
                gradient: Gradient(stops: [
                    .init(color: Cabinet.amber.opacity(0.22), location: 0),
                    .init(color: Cabinet.amber.opacity(0.08), location: 0.45),
                    .init(color: .clear, location: 0.92),
                ]),
                center: .center,
                startRadiusFraction: 0,
                endRadiusFraction: 0.5
            )
            .frame(width: 420, height: 190)
            .offset(y: 26)
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

/// Flat trophy silhouette shapes, transcribed from the brand SVG library
struct TrophySilhouette: Shape {
    enum Kind {
        case cup, star, medal, obelisk
    }

    let kind: Kind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .cup: return cup(in: rect)
        case .star: return star(in: rect)
        case .medal: return medal(in: rect)
        case .obelisk: return obelisk(in: rect)
        }
    }

    // Coordinate space 95x165
    private func cup(in rect: CGRect) -> Path {
        let s = rect.width / 95
        var p = Path()
        // Bowl
        p.move(to: point(12, 6, s, rect))
        p.addLine(to: point(83, 6, s, rect))
        p.addLine(to: point(83, 33, s, rect))
        p.addCurve(to: point(48, 84, s, rect),
                   control1: point(83, 66, s, rect),
                   control2: point(67, 84, s, rect))
        p.addCurve(to: point(12, 33, s, rect),
                   control1: point(29, 84, s, rect),
                   control2: point(12, 66, s, rect))
        p.closeSubpath()
        // Stem
        p.move(to: point(41, 84, s, rect))
        p.addLine(to: point(54, 84, s, rect))
        p.addLine(to: point(60, 108, s, rect))
        p.addLine(to: point(35, 108, s, rect))
        p.closeSubpath()
        // Base
        p.addRoundedRect(in: frame(26, 108, 43, 11, s, rect), cornerSize: CGSize(width: 3 * s, height: 3 * s))
        p.addRoundedRect(in: frame(18, 119, 59, 46, s, rect), cornerSize: CGSize(width: 4 * s, height: 4 * s))
        return p
    }

    // Coordinate space 60x117
    private func star(in rect: CGRect) -> Path {
        let s = rect.width / 60
        var p = Path()
        let points: [(CGFloat, CGFloat)] = [
            (30, 4), (37, 21), (56, 22), (42, 34), (46, 52),
            (30, 42), (14, 52), (18, 34), (4, 22), (23, 21),
        ]
        p.move(to: point(points[0].0, points[0].1, s, rect))
        for (x, y) in points.dropFirst() {
            p.addLine(to: point(x, y, s, rect))
        }
        p.closeSubpath()
        p.addRoundedRect(in: frame(24, 52, 12, 42, s, rect), cornerSize: CGSize(width: 3 * s, height: 3 * s))
        p.addRoundedRect(in: frame(12, 94, 36, 23, s, rect), cornerSize: CGSize(width: 4 * s, height: 4 * s))
        return p
    }

    // Coordinate space 75x90
    private func medal(in rect: CGRect) -> Path {
        let s = rect.width / 75
        var p = Path()
        p.addEllipse(in: frame(11, 8, 52, 52, s, rect))
        p.addRoundedRect(in: frame(31, 56, 12, 16, s, rect), cornerSize: CGSize(width: 3 * s, height: 3 * s))
        p.addRoundedRect(in: frame(17, 72, 41, 18, s, rect), cornerSize: CGSize(width: 4 * s, height: 4 * s))
        return p
    }

    // Coordinate space 55x102
    private func obelisk(in rect: CGRect) -> Path {
        let s = rect.width / 55
        var p = Path()
        p.addRoundedRect(in: frame(20, 4, 15, 60, s, rect), cornerSize: CGSize(width: 4 * s, height: 4 * s))
        p.move(to: point(27, 0, s, rect))
        p.addLine(to: point(34, 12, s, rect))
        p.addLine(to: point(21, 12, s, rect))
        p.closeSubpath()
        p.addRoundedRect(in: frame(10, 64, 35, 16, s, rect), cornerSize: CGSize(width: 3 * s, height: 3 * s))
        p.addRoundedRect(in: frame(4, 80, 47, 22, s, rect), cornerSize: CGSize(width: 4 * s, height: 4 * s))
        return p
    }

    private func point(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + x * s, y: rect.minY + y * s)
    }

    private func frame(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ s: CGFloat, _ rect: CGRect) -> CGRect {
        CGRect(x: rect.minX + x * s, y: rect.minY + y * s, width: w * s, height: h * s)
    }
}

#Preview {
    TrophyShelfView()
        .background(Cabinet.canvas)
}
