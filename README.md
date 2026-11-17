# Trophy Rooms for iOS

The iPhone and iPad app for [Trophy Rooms](https://trophyrooms.org). Track your games, physical collection, play sessions, and achievements. Built with SwiftUI and Supabase.

## Run it

You need Xcode with the iOS 26 SDK and an iOS 26 or later device or simulator.

```bash
git clone https://github.com/G3mha/trophy-rooms-ios.git
cd trophy-rooms-ios
open "Trophy Rooms.xcodeproj"
```

In Xcode, choose your signing team and set `GRAPHQL_URL`, `SUPABASE_URL`, and `SUPABASE_PUBLISHABLE_KEY` under the app target's Build Settings. Use the same Supabase project as the backend, then build and run.

For Google sign-in, allow `trophyrooms://auth-callback` in Supabase. On a physical device, use a reachable HTTPS API address rather than `localhost`.

## Related

- [Backend](https://github.com/G3mha/trophy-rooms-backend)
- [Web app](https://github.com/G3mha/trophy-rooms-web)
- [App Store assets](AppStore/README.md)
