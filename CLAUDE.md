# Trophy Rooms iOS - Development Guidelines

iOS app for Trophy Rooms (Swift, SwiftUI, Supabase).

## Required Workflow

### 1. Verify on Device

There is no CLI lint/build step. The developer builds and runs the app on a
physical iPhone from Xcode:

- Do NOT run `xcodebuild` to verify changes - it is slow and the developer
  verifies on device anyway
- After making changes, ask the developer to build and run on their phone
- HOLD commits until the developer confirms the change works on device

### 2. Commit Strategy

Always maximize the number of commits using stacked diffs style:

- Make small, atomic commits - one logical change per commit
- Each commit should be independently meaningful, reviewable, and testable
- Use clear, concise commit messages following conventional commits:
  - `feat:` - new features
  - `fix:` - bug fixes
  - `style:` - UI/styling changes
  - `refactor:` - code restructuring
  - `chore:` - maintenance tasks
  - `docs:` - documentation
- Never combine unrelated changes into a single commit

### 3. Push

```bash
git push origin main
```

## Project Notes

- The Xcode project uses file-system-synchronized groups: new Swift files
  placed in the source folders are picked up automatically, no pbxproj edits
  needed. Prefer existing folders - a brand-new directory created outside
  Xcode may not be seen until the project is closed and reopened
- SourceKit diagnostics like "No such module 'Supabase'" in editor tooling are
  index noise, not build errors - packages resolve fine in Xcode
- Do NOT use `TabView(.page)` for horizontally paged content that must extend
  under the floating tab bar: the UIKit-backed pager re-applies the window's
  bottom safe area inside each page. Use a paging `ScrollView`
  (`.scrollTargetBehavior(.paging)` + `containerRelativeFrame`) instead - see
  HomeView/CollectionView

## Visual Identity

All visual/branding work follows the "trophy cabinet" design system: see
`.claude/skills/trophy-cabinet-design/SKILL.md`. In-app: keep data UI native
and dark; the identity enters via accents (empty states, auth sheet, headers).
