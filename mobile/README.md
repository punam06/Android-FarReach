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

## Travel services

Destination details include a budget calculator with server pricing and stay searches with dates, travelers and nightly price filters. Booking confirmation uses a server quote.

Profile includes name/phone/address/password editing, saved spots, booking rescheduling and reservation receipts, support/custom trip tickets with threaded replies, and the local travel assistant. Administrators also see a support inbox. Sign in includes password reset.

See [backend contracts and local setup](../docs/TRAVEL_SERVICES.md). Stays are project catalog estimates with unknown live availability; reservation receipts are for FarReach packages. Chat runs locally against FarReach data without a paid AI API.

For the installed Pixel 6 emulator on this PC, see [emulator launch commands](../docs/EMULATOR.md) and [verified app flows](../docs/VERIFICATION.md).
