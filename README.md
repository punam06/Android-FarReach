# 🌏 FarReach — Bangladesh Tourism Mobile App

A modern **Flutter** mobile application for exploring tourist destinations across Bangladesh, backed by Firebase and an Express/MySQL REST API.

---

## 📱 Features

- **100+ Curated Destinations** — Complete coverage of Bangladesh tourist spots across all 8 divisions.
- **Offline First** — Bundled destination catalogue and fallback photography works seamlessly without an internet connection.
- **Firebase Integration**:
  - **Firebase Core & Auth** — Multi-platform initialization and user authentication.
  - **Firebase Cloud Messaging (FCM)** — Push notifications for trips, booking status, and travel updates.
- **Explore & Filter** — Filter by category (Beach, Nature, History, Culture, Wetland, City, etc.) and division.
- **Interactive Maps & Weather** — Spot coordinates and weather forecasts.
- **Trip Booking & Saved Spots** — Manage reservations, wishlist, and trip history.

---

## 🛠️ Project Structure

```text
tourismappnew/
├── android/              # Native Android project & Gradle setup
│   └── app/
│       ├── google-services.json   # Firebase Android configuration
│       └── build.gradle.kts
├── assets/               # Local asset bundle (images, icons)
├── lib/                  # Flutter application source code
│   ├── main.dart         # App entry point & Firebase initialization
│   ├── firebase_options.dart # Generated Firebase options (Android/Web)
│   ├── models/           # Data models (Destination, Booking, User)
│   ├── screens/          # Application screens (Explore, Detail, Map, Saved, Profile)
│   ├── services/         # API client, Token storage & FirebaseService
│   ├── state/            # AppController state management
│   └── theme/            # Material 3 light/dark theme system
├── test/                 # Unit, widget, and integration tests
├── server/               # Node.js / Express backend API & MySQL database
├── spot-pictures/        # Uploaded & referenced spot photography
├── pubspec.yaml          # Flutter dependencies and assets config
└── firebase.json         # Firebase project mappings
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24+ recommended)
- [Android SDK / Android Studio](https://developer.android.com/studio)
- [Node.js](https://nodejs.org/) v18+ & MySQL (for local API backend)

### 1. Install Flutter Dependencies

```bash
flutter pub get
```

### 2. Run the App

#### On Android Emulator:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

#### On Physical Android Device:
Replace `<YOUR_LOCAL_IP>` with your computer's local Wi-Fi IP (e.g. `192.168.1.5`):
```bash
flutter run --dart-define=API_BASE_URL=http://<YOUR_LOCAL_IP>:3000
```

### 3. Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APKs (smaller per-architecture files)
flutter build apk --split-per-abi
```

The compiled APK will be in:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🖥️ Running the Backend Server (Optional)

```bash
cd server
npm install
npm start
```
Default server URL: `http://localhost:3000` (or `http://10.0.2.2:3000` from Android Emulator).
