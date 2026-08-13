import SwiftUI
import UIKit

/// WCAG contrast helpers.
///
/// The cabinet palette was chosen for how it looks, and most of it clears WCAG
/// AA comfortably against the walnut surfaces (brass 6.96:1, sage 6.74:1, steel
/// 5.68:1 on `Cabinet.card`). Two tints do not: ribbon crimson lands at 3.04:1
/// and warm gray at 4.12:1, both under the 4.5:1 that small text needs.
///
/// Rather than restyle the brand, `legible(on:)` lightens a colour only where
/// it is used as *text*, and only as far as it must go to clear the threshold.
/// Fills, borders, glows and every other use keep the approved colour exactly.
extension Color {
    /// Returns this colour lightened just enough to clear `minimumRatio`
    /// against `background`, or unchanged if it already does.
    func legible(on background: Color, minimumRatio: Double = 4.5) -> Color {
        guard let fg = RGB(self), let bg = RGB(background) else { return self }
        guard ContrastCache.ratio(fg, bg) < minimumRatio else { return self }

        // Blend toward white; binary search the smallest blend that passes so
        // the colour shifts as little as the threshold allows.
        var low = 0.0
        var high = 1.0
        for _ in 0..<8 {
            let mid = (low + high) / 2
            if ContrastCache.ratio(fg.blended(toWhite: mid), bg) >= minimumRatio {
                high = mid
            } else {
                low = mid
            }
        }
        let result = fg.blended(toWhite: high)
        return Color(red: result.r, green: result.g, blue: result.b)
    }

    /// Treating this colour as a *fill*, returns whichever candidate reads best
    /// on top of it - then lifts that choice if it still falls short.
    ///
    /// Badges tint their background from the semantic palette, so no single
    /// foreground works for all of them: dark ink wins on sage, amber and
    /// brass, while the light ink wins on crimson. Picking per fill beats
    /// hard-coding either one.
    func legibleForeground(
        preferring candidates: [Color],
        minimumRatio: Double = 4.5
    ) -> Color {
        guard let bg = RGB(self) else { return candidates.first ?? self }
        let best = candidates.max { a, b in
            let ra = RGB(a).map { ContrastCache.ratio($0, bg) } ?? 0
            let rb = RGB(b).map { ContrastCache.ratio($0, bg) } ?? 0
            return ra < rb
        }
        guard let best else { return self }
        return best.legible(on: self, minimumRatio: minimumRatio)
    }
}

// MARK: - Internals

private struct RGB {
    let r, g, b: Double

    init?(_ color: Color) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        // Resolve against the dark trait the app always runs in, so semantic
        // colours (.secondary and friends) report the values actually drawn.
        let ui = UIColor(color).resolvedColor(
            with: UITraitCollection(userInterfaceStyle: .dark)
        )
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        self.r = Double(r); self.g = Double(g); self.b = Double(b)
    }

    private init(r: Double, g: Double, b: Double) {
        self.r = r; self.g = g; self.b = b
    }

    func blended(toWhite amount: Double) -> RGB {
        RGB(r: r + (1 - r) * amount,
            g: g + (1 - g) * amount,
            b: b + (1 - b) * amount)
    }

    /// WCAG relative luminance.
    var luminance: Double {
        func channel(_ c: Double) -> Double {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }
}

/// Tags render inside scrolling grids, so the same few colours get measured
/// over and over. Cache the ratios rather than recomputing `pow` per frame.
private enum ContrastCache {
    private static var store: [Key: Double] = [:]
    private static let lock = NSLock()

    private struct Key: Hashable {
        let fg: [Int]
        let bg: [Int]
        init(_ fg: RGB, _ bg: RGB) {
            // Quantise to 1/1000 so near-identical blends share an entry.
            self.fg = [Int(fg.r * 1000), Int(fg.g * 1000), Int(fg.b * 1000)]
            self.bg = [Int(bg.r * 1000), Int(bg.g * 1000), Int(bg.b * 1000)]
        }
    }

    static func ratio(_ fg: RGB, _ bg: RGB) -> Double {
        let key = Key(fg, bg)
        lock.lock()
        defer { lock.unlock() }
        if let hit = store[key] { return hit }

        let a = fg.luminance
        let b = bg.luminance
        let value = (max(a, b) + 0.05) / (min(a, b) + 0.05)
        // Bound the cache; the palette is small, this only guards runaway use.
        if store.count > 512 { store.removeAll(keepingCapacity: true) }
        store[key] = value
        return value
    }
}
