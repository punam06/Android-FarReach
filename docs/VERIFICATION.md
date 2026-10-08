# Local verification — 2026-10-09

Repository: `D:\Code\Projects\Android-FarReach`. Implementation branch: `feature/travel-services`; publication branch: `main`.
Base commit: `c67388524a05134078cefd4f95125fda25d0e336`. The verification below was completed before publication.

| Check | Result |
| --- | --- |
| `npm test` | 15 passing tests, real MySQL 8.4, isolated generated database |
| API process restart | Database session remains valid after restarting Node |
| Concurrent booking create/update | Duplicate creates rejected; 12 concurrent updates complete |
| Production OTP behavior | Missing SMTP returns 503; no preview codes or undelivered signup records |
| `npm audit --omit=dev` | Zero reported vulnerabilities |
| `flutter analyze --no-pub` | No issues |
| `flutter test --no-pub` | 21 passing tests, including phone layouts, Explore golden, signup/logout state and saved destination navigation |
| `flutter build apk --debug --no-pub` | Installable debug APK produced |
| Docker build/start | API and MySQL healthy; API runs as UID 1000 (`node`) |
| Docker live workflow | OTP signup/login, package booking, related ticket, chatbot booking count and day-trip pricing passed; temporary account removed |
| `git diff --check` | Passed using the repository's existing CRLF conventions |

APK: `mobile/build/app/outputs/flutter-apk/app-debug.apk` (185,969,792 bytes), rebuilt and installed after the emulator fixes.

SHA-256:

```text
e9421d5fb9f1431a883ee5a4695b8b701d7400fd9bf646d86b0853f7d3ad9926
```

The APK uses the debug emulator API address `http://10.0.2.2:3000`. For a physical phone, build with the appropriate `API_BASE_URL` described in [the setup guide](TRAVEL_SERVICES.md).

The first Android build exposed Kotlin incremental cache failures across the C:/D: drives. The verified build disables incremental Kotlin compilation, runs the compiler in the Gradle process, and uses two workers with a 4 GiB heap. The SDK emitted an XML-version warning, but the final build succeeded.

## Installed Android checks

FarReach ran through `flutter run` in the visible `FarReach_Travel_API_36` Pixel 6 emulator (`emulator-5554`, Android 16 / API 36). The Docker API served the app at `http://10.0.2.2:3000`.

| App flow | Observed result |
| --- | --- |
| Explore | 82 destinations loaded from the API; Lalbagh Fort search returned one match |
| Authentication | Local-preview OTP signup, sign-out and subsequent sign-in succeeded |
| Profile | Name changed to FarReach Demo; phone and Dhaka address saved |
| Saved spots | Lalbagh Fort saved to the account and displayed in Saved |
| Budget | One traveler, one day, Dhaka → Lalbagh Fort: ৳500 total, ৳0 accommodation |
| Suggested stays | Dhaka catalog loaded; maximum nightly price ৳3,000 returned Hotel 71 at ৳1,600 |
| Booking | October 20, two travelers: quoted and booked at ৳1,600; reservation receipt displayed |
| Booking management | Changed to October 21 and three travelers after reviewing the ৳2,400 server quote; updated receipt displayed |
| Custom tickets | Created Custom Dhaka trip linked to the booking; reply persisted; close and reopen both succeeded |
| Chat | My bookings returned one active reservation; a custom-trip help response opened the ticket form |
| App process restart | Secure session restored; edited profile, saved spot, updated booking and chat history remained available |
| Final installed-build navigation/logs | Opened Lalbagh Fort from Saved and Explore; no Flutter exception, overflow or Android fatal-error matches in captured app logs; crash buffer empty |

Emulator interaction found and fixed two additional defects: signing out after registration left the signup password step selected, and inactive Explore/Saved tabs shared destination Hero tags during navigation. Both have regression tests. The app's auth form now resets to sign-in after successful authentication, and only the active tab enables Hero animations.

Local UI XML, screenshots and logs are stored under ignored `test-results/emulator/`. See [this PC's emulator setup](EMULATOR.md) for launch commands. The local demo account is `emulator.demo.20261009@example.test`; its records remain in the local development database for review.

SMTP delivery to real recipients, live hotel inventory/payment settlement, external property links and release signing were not tested. The chatbot uses local rules/catalog data and stays use clearly labeled project catalog estimates.
