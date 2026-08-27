# FarReach Tourism — Flutter Mobile App

Android Flutter client for the existing Express + MySQL backend (`../server`).

## Run

1. Start the backend:
   ```bash
   cd ../server && npm run dev   # listens on http://localhost:3000
   ```
2. Run the app (emulator uses `10.0.2.2` to reach the host):
   ```bash
   flutter run
   ```
   For a physical device, change `baseUrl` in `lib/core/constants/api_constants.dart`
   to your computer's LAN IP.

## Architecture (feature-first, layered)

```
lib/
├── main.dart                  # entry point, Provider setup
├── app.dart                   # root widget + bottom-nav shell
├── core/
│   ├── constants/             # API base URL & endpoint constants
│   ├── network/api_client.dart# HTTP client w/ X-Session-Token auth
│   ├── theme/app_theme.dart   # colors & Material theme
│   └── widgets/               # shared loading/error/empty widgets
└── features/
    ├── auth/          (domain / data / presentation)
    ├── destinations/  (domain / data / presentation)
    └── bookings/      (domain / data / presentation)
```

Each feature follows: `domain` (entities + repository contracts),
`data` (REST implementations), `presentation` (ChangeNotifier providers + screens).

## Dependencies

http · provider · shared_preferences · cached_network_image · intl

# tourism_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
