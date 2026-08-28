# FarReach Android

Flutter Material 3 client for the FarReach Bangladesh tourism API. It includes an offline destination guide, responsive Explore/Map/Saved/Profile navigation, secure session storage, account-scoped favorites, OTP registration, weather, hotel suggestions, and trip booking.

From this folder:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
flutter analyze
flutter test
flutter build apk --debug
```

Use `10.0.2.2` for the Android emulator. For a physical phone, replace it with the development computer's LAN IP. Debug builds allow local HTTP. Release builds do not fall back to the emulator address and require an explicit HTTPS API:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com
```

Without the define, browsing continues from the offline catalog and live services fail safely. Configure release signing with a private keystore outside source control before publishing.
