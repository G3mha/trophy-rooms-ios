import SwiftUI

/// Trophy cabinet design system (see .claude/skills/trophy-cabinet-design).
/// The data UI stays native and dark; these tokens carry the identity into
/// accents: display type, the auth sheet, headers, and empty states.
enum Cabinet {
    // MARK: - Palette

    static let walnut = Color(red: 0.169, green: 0.106, blue: 0.063)      // #2b1b10
    static let walnutDeep = Color(red: 0.141, green: 0.082, blue: 0.035)  // #241509
    static let ink = Color(red: 0.051, green: 0.031, blue: 0.020)         // #0d0805
    static let bone = Color(red: 0.937, green: 0.906, blue: 0.824)        // #efe7d2
    static let brass = Color(red: 0.788, green: 0.643, blue: 0.361)       // #c9a45c
    static let brassDeep = Color(red: 0.541, green: 0.416, blue: 0.200)   // #8a6a33
    static let crimson = Color(red: 0.788, green: 0.173, blue: 0.235)     // #c92c3c
    static let shadowRed = Color(red: 0.478, green: 0.102, blue: 0.133)   // #7a1a22

    // MARK: - Semantic tints
    //
    // Category colors keep their hue identity (blue reads as blue) but are
    // desaturated and warmed so they sit inside the cabinet instead of
    // glowing neon against the walnut. Use these for every tag tint.
    enum Tint {
        /// Neutral / default / editions
        static let neutral = Color(red: 0.788, green: 0.643, blue: 0.361)  // brass
        /// Informational category (games, base content)
        static let info = Color(red: 0.463, green: 0.616, blue: 0.729)     // muted steel
        /// Secondary category (DLC, season pass)
        static let violet = Color(red: 0.639, green: 0.514, blue: 0.702)   // muted plum
        /// Tertiary category (bundles, collections)
        static let amber = Color(red: 0.851, green: 0.635, blue: 0.353)    // warm amber
        /// Positive / complete / mint
        static let positive = Color(red: 0.502, green: 0.702, blue: 0.494) // muted sage
        /// Attention / high priority / poor condition
        static let alert = Color(red: 0.788, green: 0.173, blue: 0.235)    // crimson
        /// In progress / paused
        static let warm = Color(red: 0.855, green: 0.522, blue: 0.290)     // burnt orange
        /// Inactive / dropped / unknown
        static let muted = Color(red: 0.545, green: 0.494, blue: 0.427)    // warm gray
    }

    // MARK: - Surfaces

    /// Screen canvas: walnut-black instead of system black
    static let canvas = Color(red: 0.078, green: 0.063, blue: 0.035)      // #141009
    /// Card surface: warm brown instead of system gray
    static let card = Color(red: 0.157, green: 0.118, blue: 0.078)        // #281e14
    /// Warm cabinet light for glows
    static let amber = Color(red: 1.0, green: 0.816, blue: 0.541)         // #ffd08a

    // MARK: - Typography

    /// Poster display type (uppercase headlines)
    static func display(_ size: CGFloat) -> Font {
        .custom("Anton-Regular", size: size)
    }

    /// Script accent - use sparingly, one flourish per screen
    static func script(_ size: CGFloat) -> Font {
        .custom("Yellowtail-Regular", size: size)
    }
}

// MARK: - Canvas backdrop

/// Warm screen backdrop: walnut-black with a faint cabinet spotlight from
/// the top, replacing the system's pure black
struct CabinetCanvas: View {
    var body: some View {
        ZStack {
            Cabinet.canvas
            RadialGradient(
                colors: [Cabinet.amber.opacity(0.07), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Applies the cabinet canvas behind a screen's content
    /// Applies the cabinet canvas behind a screen's content.
    ///
    /// Note: a background sizes to its host, so content that does not fill the
    /// screen leaves the rest black. Views used as a whole-screen state (see
    /// `CabinetLoadingView`) fill themselves rather than forcing a fill here -
    /// forcing it globally breaks layout for hosts inside scroll views.
    func cabinetCanvas() -> some View {
        background(CabinetCanvas())
    }
}
