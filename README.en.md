<div align="center">

# HTV · Local IPTV Player

**No bundled channel list and no account. Import your own playlist for Android phones, TVs and TV boxes.**

[![Platform](https://img.shields.io/badge/Android-4.4%2B-brightgreen)](#build-from-source)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

</div>

---

## An empty-shell player

HTV ships without channel sources and does not require an account. The list is empty on first launch; channels come only from a playlist that you import. Remote-control and touch navigation, favorites, failover, catch-up and EPG features remain (catch-up and EPG depend on the playlist or guide provider).

## Import a playlist

1. On the TV, open **Settings → Subscription URL → QR code**.
2. Connect your phone and TV to the same local network. Scan the QR code and manually paste a playlist URL into the blank page.
3. Tap **Import to TV**. The TV fetches the playlist from that URL.

Supported formats: **M3U, TXT (`#genre#`), and XSPF**. The parser also retains compatibility with the project's JSON list format. No playlist URL is prefilled or hardcoded. Importing a new URL replaces the saved one.

The QR page uses no pairing token. The LAN service exposes only the import page and playlist-import endpoint, runs only while the QR page is open, and stops when you leave it. Use it on a trusted home network.

## Local data and privacy

The subscription URL, downloaded playlist, EPG cache and app settings are stored in the TV's private local app storage. They are not uploaded to a cloud account or remote control backend. On upgrade, the old user-playlist cache is migrated to persistent local storage; legacy bundled-channel cache and user identifiers are removed.

Network access is used only to fetch the URL the user entered, obtain EPG data, play channel streams, and query GitHub release information when version information is viewed. The app has no ad or analytics SDK and no remote command, remote configuration, or cloud playlist-storage endpoint.

## Build from source

For Android 4.4 (API 19), use **Flutter 3.19.6** (Flutter 3.22 raised the minimum Android API to 21), JDK 17, and Android SDK 34. `android/app/build.gradle` explicitly sets `minSdkVersion 19`.

```bash
flutter pub get
flutter test
flutter analyze
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/`. Without a release keystore, the build uses a debug signing key and is suitable for installation testing. Use your own signing key for public releases.

## License

Apache License 2.0; see [LICENSE](LICENSE).
