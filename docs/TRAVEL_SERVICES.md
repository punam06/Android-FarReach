# FarReach travel services

The repository was cloned from `punam06/Android-FarReach`, with a clean `main` at `c673885` ("Replace main with Sayed branch"). The travel services and emulator fixes were developed on `feature/travel-services` for publication to `main`.

## Feature status

| Feature | Initial state | Implemented behavior |
| --- | --- | --- |
| Authentication | OTP signup and login; sessions held in memory | Seven-day database sessions, hashed session tokens, signup verification proof, login throttling, password reset, session revocation |
| Suggested stays | Hardcoded suggestions with fabricated availability | Validated dates, traveler/room estimates, price filtering, explicitly unknown availability, no fabricated fallback properties |
| Booking | Create, list, cancel | Server quote, concurrent duplicate protection, reprice/reschedule, Dhaka cancellation policy, reservation references and receipts |
| Budget pricing | Web calculations and duplicated mobile package rates | Shared server pricing, category/tier options, origin districts, per-component BDT estimates and correct zero-night day trips |
| Chatbot | Absent | Account-scoped Gemini travel assistant when configured, Markdown topic policy, database conversation history, local fallback, deliberate ticket creation action |
| Tickets | Absent | Support/custom trip requests, optional booking association, threaded replies, close/reopen, admin inbox and status management |
| Profile | Mobile account summary and basic booking cancellation | Edit name/phone/address/password; saved spots, booking management and receipts, tickets, chat, account refresh |

## Run locally

Docker Desktop must be running with Linux containers. From the repository root:

```powershell
docker compose up -d --build --wait
```

The web client and API run at `http://127.0.0.1:3000`; MySQL is available at `127.0.0.1:3308`. Compose uses persistent named volumes. The schema is imported only when the MySQL volume is first initialized; additive migrations run on API startup. Do not reimport `database.sql` over a populated database: that original dump recreates tables.

Compose is configured for local development with local OTP previews and loopback ports. Its default database credentials are development credentials. Supply `DB_PASSWORD` and `MYSQL_ROOT_PASSWORD` in a root `.env` or the shell to replace them before creating the database volume. Changing these values does not change passwords inside an existing volume.

To run Node directly against the compose database, install Node 20+ and create `server/.env`:

```dotenv
NODE_ENV=development
DB_HOST=127.0.0.1
DB_PORT=3308
DB_USER=farreach
DB_PASSWORD=farreach-local-only
DB_NAME=torisom_db
PORT=3000
APP_API_BASE_URL=http://127.0.0.1:3000
```

Stop only the container API first with `docker compose stop api`, then run `npm ci` and `npm start` from `server`. The MySQL service remains available. The existing `server/.env.example` includes SMTP configuration. `NODE_ENV=production` requires working SMTP for signup and password resets and never returns preview codes.

Flutter Android:

```powershell
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

For a USB-connected phone, `adb reverse tcp:3000 tcp:3000` lets a build configured with `API_BASE_URL=http://127.0.0.1:3000` reach the local server. Compose binds ports to loopback by default; direct LAN access needs a deliberate bind/firewall configuration. Release builds require an explicit HTTPS endpoint and a private signing configuration.

## Authentication contract

Use `Authorization: Bearer <token>`. Sessions expire seven days after sign in, survive API restarts, and are revoked on logout. Updating a password requires `current_password` and revokes the user's other sessions. Password reset revokes all sessions.

Signup:

1. `POST /api/auth/signup/start` with `{name,email}`; development without SMTP returns `previewCode`.
2. `POST /api/auth/signup/verify-code` with `{email,code}`; save `verificationToken`.
3. `POST /api/auth/signup/set-password` with `{name,email,password,verificationToken}`.

The final step requires the proof returned by verification. Both the Flutter client and the served/root web clients were updated. Older clients that submit only an email/password after OTP verification must be updated.

Password reset:

1. `POST /api/auth/password-reset/start` with `{email}`. The normal response does not disclose whether the account exists. A preview is returned only for an existing account in development without working SMTP.
2. `POST /api/auth/password-reset/complete` with `{email,code,password}`. Codes expire after ten minutes, allow five failed guesses, and are consumed on success.

Passwords must have at least eight characters and at most 72 UTF-8 bytes. Login throttles email and IP attempts; OTP request and verification limits remain active. Login/OTP request windows are process-local, while OTP failed attempts and password reset counters persist in MySQL.

`PUT /api/auth/profile` accepts JSON or multipart fields `name`, `phone`, `address`, optional `password` plus `current_password`, and optional multipart `profile_pic` (existing image upload support). Omitted profile fields are retained; email/role cannot be changed through this endpoint.

## Public pricing and stay APIs

| Method | Route | Input / result |
| --- | --- | --- |
| GET | `/api/pricing` | Available origin districts, tiers, transport modes, currency and pricing version |
| POST | `/api/budget/estimate` | `spot_id`, optional `persons` (1–20), `days` (1–30), `origin`, `hotel_tier`, `food_tier`, `guide_tier`, `transport_mode`; returns `estimate` |
| POST | `/api/bookings/quote` | `spot_id`, `persons`, `booking_date`; returns server `quote` |
| POST | `/api/stays/search` | Alias of `/api/hotels/search`; destination/city/category, optional date pair, `persons`, `max_price` |

Example budget request:

```json
{"spot_id":24,"persons":2,"days":3,"origin":"Dhaka","hotel_tier":"normal","food_tier":"standard","guide_tier":"local","transport_mode":"bus_nonac"}
```

Use IDs from `GET /api/spots`, not the illustrative ID above. `estimate.breakdown` contains accommodation, food, local transport, guide and round-trip transport. `nights = days - 1`; lodging is estimated per traveler and guides per group/day. Origin equal to destination district incurs zero inter-district travel. Other distances use district coordinates and a 1.3 road factor. Modes represent planning rates; routes and supplier fares are not verified. Supported districts come from the existing destination dataset and are listed by `/api/pricing`.

Package reservations have a separate fixed per-traveler rate by destination budget category: Low 800, Mid 1250, High 1700 BDT. Neither client submits an authoritative price. The web calculator and booking confirmation now use the same server APIs as Flutter.

Stay results use the inherited project catalog for recognized destinations. Rates are explicitly estimates. `availability` is always `unknown`, `live_availability` is false, and unsourced ratings are omitted. There is no live supplier integration. For unconfigured destinations the API returns an empty list. A stay has `price` per room/night, `rooms = ceil(persons / 2)`, `nights`, `total_estimate`, and an external lookup link. Date pairs must be valid, ordered, not in the past, and at most 30 nights apart. `max_price` filters the estimated nightly rate.

## Booking management

| Method | Route | Behavior |
| --- | --- | --- |
| POST | `/api/bookings` | Reserve with `{spot_id,booking_date,persons}`; responds 201 with `booking` |
| GET | `/api/user/bookings` | Own bookings including `reference`, `currency`, `can_modify` |
| PUT | `/api/user/bookings/:id` | Change `{booking_date,persons}` and reprice |
| DELETE | `/api/user/bookings/:id` | Cancel own booking |
| GET | `/api/user/bookings/:id/ticket` | Own reservation receipt; `valid` only for confirmed status |
| PUT | `/api/admin/bookings/:id/status` | Admin status: pending, confirmed, cancelled |

Creation and rescheduling lock the user row before duplicate checks, so concurrent requests cannot create two active bookings for the same user/spot/date. Existing booking dates and new input dates use `Asia/Dhaka`; changes/cancellations require at least 24 hours until midnight on the booked date. New dates must be within the next year. Ownership is checked in SQL; another user's booking returns 404. Cancellation invalidates the receipt.

These are FarReach package reservations. No payment, hotel inventory hold, airline/rail issuance or attraction admission is performed. The receipt explicitly states this limitation.

## Trip requests and quotes

| Method | Route | Behavior |
| --- | --- | --- |
| GET | `/api/travel/providers` | Available provider preferences; all report `live_booking: false` |
| POST | `/api/trip-requests` | Submit a request with an `Idempotency-Key` header |
| GET | `/api/user/trip-requests` | Own paginated requests; accepts `page`, `limit`, and `status` |
| GET | `/api/user/trip-requests/:id` | Own request, quotes, and status history |
| POST | `/api/user/trip-requests/:id/accept` | Accept the current quote and its terms with `{version,quote_id,accept_terms:true}` |
| POST | `/api/user/trip-requests/:id/cancel` | Cancel an unconfirmed request or request cancellation of a confirmed trip |
| GET | `/api/admin/trip-requests` | Admin paginated request inbox |
| GET | `/api/admin/trip-requests/:id` | Admin request detail |
| POST | `/api/admin/trip-requests/:id/quotes` | Publish an itemized quote with an itinerary, cancellation policy, and expiry |
| POST | `/api/admin/trip-requests/:id/confirm` | Record supplier confirmation after customer acceptance |
| POST | `/api/admin/trip-requests/:id/close` | Reject a request or record a supplier cancellation |

Request creation needs service, provider preference, origin, destination, dates, traveler counts, contact details, and an optional BDT-paisa budget and requirements. A per-account limit of ten new requests per day applies. Every state-changing request after creation includes the current `version`; a stale version returns 409 so the traveler can review the latest quote or status before acting. Quotes contain integer BDT-paisa line items and expire no later than the trip start. The status path is `requested → quoted → awaiting_confirmation → confirmed`; cancellation and rejection have separate transitions. Trip.com and GoZayaan are preferences or external links, not connected inventory or booking APIs. FarReach does not collect payment or claim a supplier booking until an operator records confirmation details.

## Support tickets and chatbot

| Method | User route | Behavior |
| --- | --- | --- |
| POST | `/api/user/tickets` | `{subject,description,category,booking_id?}` |
| GET | `/api/user/tickets?page=1&limit=25` | Own paginated tickets |
| GET | `/api/user/tickets/:id` | Ticket and reply thread |
| POST | `/api/user/tickets/:id/messages` | `{message}`; rejects replies to closed/resolved tickets |
| PUT | `/api/user/tickets/:id/status` | User may set open (reopen) or closed |
| GET | `/api/chatbot/messages` | Last 100 conversation messages |
| POST | `/api/chatbot/messages` | `{message}`; returns `reply`, optional `action`, and assistant mode |
| DELETE | `/api/chatbot/messages` | Delete own conversation |

Ticket categories: `general`, `booking`, `custom_trip`, `account`, `payment`. A booking category requires an owned booking ID. Custom travel requirements go in the description: destination, dates, travelers, budget, special requests. Subject limit is 150 characters, details/replies 5,000 characters, and chat input 1,000 characters. Ticket creation is limited to ten/hour/account; chat to twenty/minute/account. List limits are 1–100; default is 50.

Admin endpoints use `/api/admin/tickets` with the same list/detail/messages/status paths, and allow statuses open, in_progress, resolved and closed. They require the existing admin role. No public role promotion was added. The Flutter profile shows a Support inbox for admins.

With `GEMINI_API_KEY` set on the server, the chatbot uses Gemini 3.5 Flash-Lite. Its allowed topics and app facts are defined in [`server/CHATBOT_SCOPE.md`](../server/CHATBOT_SCOPE.md), which the server loads as instructions. Gemini classifies each question; out-of-scope questions receive a fixed reminder instead of the generated answer. The server sends only recent conversation turns, matching public catalog names, and an active reservation count when relevant. Chat is still account-scoped and rate-limited. Without the key, the existing local rules/catalog assistant remains available. A `create_ticket` action opens a form; chat never creates tickets or changes bookings automatically. Set the key in ignored `server/.env` for local Node or Docker Compose; production should inject it as a server environment variable. Do not put it in Flutter build arguments or commit it.

## Verification

From the root, `docker compose up -d --wait db`, then from `server`:

```powershell
npm ci
npm test
npm audit --omit=dev
```

Tests create and drop only a randomly named `farreach_test_<hex>` database. They require a MySQL account able to create/drop databases. Defaults match this local compose database: root, port 3308, password `farreach-root-local-only`. Override `TEST_DB_HOST`, `TEST_DB_PORT`, `TEST_DB_USER`, and `TEST_DB_PASSWORD` when needed. Tests never use the application database for their fixtures.

Coverage includes OTP proof, restart persistence, logout, pricing validation/day trips, honest stay estimates, concurrent booking creation, repricing and cancellation, receipt validity, account isolation, ticket/admin workflows, chatbot persistence and scope handling, trip request idempotency, quote expiry and state transitions, profile password/session handling, reset-code consumption, and malformed JSON handling.

From `mobile`: `flutter analyze`, `flutter test`, `flutter build apk --debug`. Additional UI tests run the new flows at 412px and 320px phone widths, including reviewing a server quote before booking changes. SMTP delivery, live supplier reservations and release signing require external configuration.

Kotlin incremental compilation is disabled in this checkout because the Windows project is on D: and the Flutter package cache is on C:. This prevents the compiler's cross-drive relative-path cache failure.
