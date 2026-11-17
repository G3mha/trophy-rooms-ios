# Trophy Rooms for iOS

The native iPhone and iPad app for [Trophy Rooms](https://trophyrooms.org), a home for the games you play, the copies you collect, and the achievements you earn.

Built by Enricco Gemha with SwiftUI. Supabase handles sign-in; the shared [GraphQL backend](https://github.com/G3mha/trophy-rooms-backend) stores the catalog, collections, play history, and achievement progress. The [web app](https://github.com/G3mha/trophy-rooms-web) uses the same API.

## What you can do

- Organize your library by backlog, playing, paused, completed, or dropped.
- Catalog physical copies, regions, condition, packaging, editions, and bundles.
- Keep buy and sell lists.
- Log play sessions and review your journal and statistics.
- Tick off achievements manually and display completed games in your trophy room.
- Browse community activity and leaderboards.

Achievement lists are available for a subset of the catalog. Progress is recorded manually; the app does not automatically synchronize achievements from consoles or PC stores.

## Build and run

You need macOS, Xcode with the iOS 26 SDK, and an iOS 26 or later device or simulator. The project currently targets iOS 26.0. A physical-device build also needs an Apple development team and appropriate signing capabilities.

```bash
git clone https://github.com/G3mha/trophy-rooms-ios.git
cd trophy-rooms-ios
open "Trophy Rooms.xcodeproj"
```

1. Let Xcode resolve the Swift packages: Supabase Swift and Kingfisher.
2. Select the **Trophy Rooms** app target. Under **Signing & Capabilities**, choose your development team and a bundle identifier you can sign. Configure Sign in with Apple for that identifier if you want Apple sign-in.
3. Under **Build Settings**, add these user-defined settings for the configuration you run. The root `Info.plist` expands them into the app bundle:

   | Setting | Value |
   |---|---|
   | `GRAPHQL_URL` | Your development API endpoint, such as `http://localhost:4000/graphql` for a simulator using a local backend |
   | `SUPABASE_URL` | Your Supabase development project URL |
   | `SUPABASE_PUBLISHABLE_KEY` | That project's public/publishable key |

4. Use the same Supabase project as the backend. For Google sign-in, enable the provider and allow `trophyrooms://auth-callback` in Supabase Auth's redirect URLs. Apple sign-in also needs the matching provider configuration.
5. Choose the **Trophy Rooms** scheme, select a destination, and run from Xcode.

Follow the backend's setup instructions first. On a physical iPhone, `localhost` refers to the phone: use a reachable development API URL instead. An HTTPS development endpoint avoids App Transport Security restrictions on plain HTTP. Use a development backend and account for testing.

The Supabase service-role key belongs on the server and must never be placed in the app. The app only needs the publishable key and a user's session token.

## Project layout

| Path | Purpose |
|---|---|
| `Trophy Rooms/TrophyRoomsApp.swift` | App entry point |
| `Trophy Rooms/Views/` | Screens and sheets |
| `Trophy Rooms/ViewModels/` | Screen state and presentation logic |
| `Trophy Rooms/Models/` | Client data models |
| `Trophy Rooms/Network/` | Supabase authentication and GraphQL requests |
| `Trophy Rooms/Cache/` | Cached data and account-scoped invalidation |
| `Trophy Rooms/Components/` | Shared UI components |
| `Trophy RoomsTests/`, `Trophy RoomsUITests/` | Xcode test targets |
| `AppStore/` | Listing copy and screenshot-card generation source |

`AuthManager` owns the Supabase session. `NetworkService` sends GraphQL operations with the session's bearer token. Both read configuration through `Info.plist`; the web app's environment variables do not configure iOS.

## Development

Build and run through Xcode. For behavior or UI changes, verify the affected flow on a physical iPhone before committing. Check sign-in, catalog loading, the changed feature, and sign-out with a development account. See [CLAUDE.md](CLAUDE.md) for development conventions.

The test targets currently include starter tests, so their presence alone does not establish feature coverage.

For the App Store listing and reproducible promotional cards, see [AppStore/README.md](AppStore/README.md) and [AppStore/listing.md](AppStore/listing.md).

## Related repositories

- [trophy-rooms-backend](https://github.com/G3mha/trophy-rooms-backend) — GraphQL API, database schema, and catalog tools.
- [trophy-rooms-web](https://github.com/G3mha/trophy-rooms-web) — Next.js client.

## Author

Created and maintained by Enricco Gemha.
