# App Store assets

Everything needed to rebuild the App Store listing from scratch. The images
themselves are **not** committed - they are build output, and the PNGs run to
~110 MB per release. What lives here is the source that reproduces them.

Regenerating from the same screenshots produces byte-identical cards, so the
generator is the archive.

```
AppStore/
├── listing.md          copy for the product page (verified under Apple's limits)
├── review-notes.md     what goes in App Review Information
└── generator/
    ├── generate.py     builds all 10 promo cards, then the upload-sized set
    ├── out/            (ignored) full-size cards + the HTML each was rendered from
    └── upload/         (ignored) resized to the exact dimensions ASC accepts
shots/                  (ignored) raw simulator screenshots - the only manual input
```

## Rebuilding

**1. Retake the screenshots.** Run the app in the simulator and capture the
eleven shots below into `AppStore/shots/`. Names matter - `generate.py` looks
them up by filename.

| iPhone (6.9", e.g. 16 Pro Max) | iPad (13", e.g. Pro M4) |
| --- | --- |
| `ip-home.png` | `ipad-home.png` |
| `ip-library.png` | `ipad-library.png` |
| `ip-collection.png` | `ipad-collection.png` |
| `ip-journal.png` | `ipad-trophies.png` |
| `ip-logplay.png` | `ipad-detail.png` |
| `ip-detail.png` | |

Sign in as the demo account first so no screen looks empty, and re-run the
backend's `scripts/seed-demo-account.ts` beforehand - the play streak decays,
and a screenshot showing a 0-day streak undersells the feature.

**2. Build the cards.**

```bash
python3 AppStore/generator/generate.py
```

Needs Google Chrome at the standard `/Applications` path; it renders each card
headless at an exact pixel canvas. Takes about 40 seconds. No Python packages
are required.

**3. Upload** everything in `generator/upload/` to App Store Connect.

## Why two sizes

The cards render at the native 6.9" and 13" canvas (1320×2868 and 2064×2752),
then downsample to 1284×2778 and 2048×2732. Those are the 6.5" iPhone and 12.9"
iPad slots, and App Store Connect rejects anything that is not an exact listed
size - uploading the native sizes fails. `generate.py` does this in its last
step; use `upload/`, not `out/`.

## Design

The cards follow the trophy cabinet identity - walnut ground, Anton display
type with a hard crimson offset, Yellowtail script accents, engraved brass
plaques, and backlit trophy silhouettes. See
`.claude/skills/trophy-cabinet-design/SKILL.md`.

Each card composes the device at a different angle, offset and scale so the set
reads as a series rather than one template repeated. Keep that variety if you
add cards.
