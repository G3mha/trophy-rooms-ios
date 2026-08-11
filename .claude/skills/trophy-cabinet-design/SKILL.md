---
name: trophy-cabinet-design
description: Trophy Rooms' "trophy cabinet" visual identity. Use when styling ANY Trophy Rooms visual surface - web pages, iOS views, App Store assets, marketing cards, email templates, or empty states - so every surface stays on the approved brand.
---

# Trophy Cabinet Design System

Trophy Rooms' brand identity (approved Aug 2026): a sports trophy cabinet in a
wood-paneled den - sleek 50s-cartoon, moody and warm. Think Saul Bass poster
meets a varsity trophy case. NEVER bright, pastel, or circus-like; that
direction was explicitly rejected.

## Palette

| Token | Hex | Role |
|---|---|---|
| walnut | `#2b1b10` | backgrounds (base wood tone) |
| walnut-deep | `#241509` | background gradients, plank seams |
| ink | `#0d0805` | silhouettes, darkest shadows |
| bone | `#efe7d2` | display text, outlines on dark |
| brass | `#c9a45c` | script accents, frames, plaque highlights |
| brass-deep | `#8a6a33` | plaque gradients, borders |
| crimson | `#c92c3c` | THE accent: ribbons, hard text shadows, CTAs |
| shadow-red | `rgba(122,26,34,0.85)` | hard offset shadow behind display type |

Web (globals.css): exposed as `--cabinet-walnut`, `--cabinet-bone`,
`--cabinet-brass`, `--cabinet-brass-deep`, `--cabinet-crimson`, `--cabinet-ink`.
The app's existing crimson (`--nintendo-red`) stays for the data UI; cabinet
tokens are for marketing/identity surfaces.

## Typography

- **Display / headlines**: Anton (Google Fonts), UPPERCASE, tight line-height
  (~1.05), letter-spacing ~2px, bone color, with a HARD offset shadow
  (`text-shadow: 8px 8px 0 rgba(122,26,34,0.85)` scale-adjusted). Never blurred.
- **Script accent**: Yellowtail (Google Fonts), brass color, rotated -2.5deg,
  used SPARINGLY - one kicker/flourish per surface ("Your Library", "Day by day").
- **Plaque labels**: Anton, small size, wide letter-spacing (10-12px), dark
  brown `#3a2a12` engraved on a brass gradient plate.
- Body/UI text stays the platform default (Geist on web, SF Pro on iOS) -
  the identity lives in display type and accents, never in data-dense UI.

## Motifs (in descending order of use)

1. **Wood paneling**: layered CSS gradients - plank seams every ~216px, subtle
   grain streaks, tonal variation. See the card generator for the exact recipe.
2. **Cabinet lighting**: one warm spotlight pool from above
   (`radial-gradient(ellipse, rgba(255,208,138,0.16), transparent)`) + dark
   vignette at edges. Scenes are dim; light is warm (amber), never white.
3. **Trophy silhouettes**: trophies appear ONLY as crisp black (`#0d0805`)
   silhouettes backlit by warm glow (`rgba(255,196,116,~0.4)`). Shapes: cup,
   star trophy, medal-on-stand, obelisk. NEVER render lit/detailed/gradient
   trophy illustrations - that was tried and rejected as fake-looking.
4. **Brass plaques**: engraved nameplate labels (brass gradient, 3px dark
   border, inset highlight) for section labels.
5. **Glass sheen**: diagonal bone-white gradient stripes at ~5-8% opacity
   overlaying a scene = looking through a cabinet door. Marketing only.
6. **Hard shadows everywhere**: solid offset shadows (print style), never
   blurred drop-shadows, on display type and framed objects.
7. **Shelf**: lit wooden shelf edge (bone-to-walnut vertical gradient strip)
   grounding displayed objects; objects sit ON it, never float.

## Rules

- Data-dense UI (grids, lists, forms) keeps its current dark theme and system
  typography; the cabinet identity enters through accents: headings, empty
  states, hero/marketing panels, badges, section labels.
- One script flourish max per screen. One crimson accent family - do not add
  new hues (no teal/mustard; rejected).
- Framed objects (screenshots, covers as hero pieces) get thin brass frames
  (`border: ~8px solid #a5824a`) and stand straight, not tilted.
- Silhouette compositions vary between surfaces (heights, shapes, clusters) so
  repeated use feels like different shelves of one cabinet.

## Reference implementations

- **App Store card generator**: `docs/branding/generate_cards.py` (in the web
  repo) - renders the 12 store cards via headless Chrome; contains the complete
  CSS recipes (wood, light, glass, plaque, compartment) and the SVG silhouette
  shape library. Regenerate cards by editing CARDS_DEF and running
  `python3 generate_cards.py`.
- **Web tokens/fonts**: `trophy-rooms-web/src/app/globals.css` (cabinet custom
  properties) and `src/app/layout.tsx` (Anton + Yellowtail via next/font).
