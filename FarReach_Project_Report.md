# Project Report — CSE 4104: Software Development Project – II

**Project Title:** FarReach — Bangladesh Tourism Explorer  
**Technology:** Flutter (Dart) + Node.js + MySQL + Firebase  
**Course:** CSE 4104 – Software Development Project II  
**Version:** 1.0.0

---

## Abstract

FarReach is a cross-platform mobile application designed to simplify tourism exploration in Bangladesh. Bangladesh is a country rich in natural, cultural, and historical heritage — from the world's longest sea beach at Cox's Bazar to the UNESCO-listed Sundarbans mangrove forest — yet travelers often face difficulty in discovering, planning, and booking visits to these destinations.

FarReach addresses this gap by offering an integrated platform where users can browse over twenty tourist spots across all eight divisions of Bangladesh, filter by category and budget, view real-time weather forecasts, save favourite spots, make and manage bookings, and get AI-generated day-by-day trip plans. An in-app AI guide powered by Google Gemini provides conversational support for first-time and experienced travellers alike. The app also embeds a safety and emergency directory for each destination.

The application is built with Flutter for a fully native Android experience (with tablet and large-screen adaptive layouts), backed by a Node.js/Express REST API and a MySQL database, and enriched with Firebase Authentication and Cloud Messaging. Key third-party integrations include the Open-Meteo API for live weather forecasts and Google Gemini for AI planning and chat.

The result is a polished, offline-capable tourism companion that empowers Bangladeshi and international travellers to plan and experience the country's best destinations responsibly and confidently.

---

## Table of Contents

1. [Introduction](#1-introduction)
   - 1.1 Project Overview
   - 1.2 Problem Statement
   - 1.3 Objectives / Goals
   - 1.4 Scope of the Project
   - 1.5 Target Users
   - 1.6 Limitations
2. [Literature Review / Related Work](#2-literature-review--related-work)
3. [Requirement Analysis](#3-requirement-analysis)
   - 3.1 Functional Requirements
   - 3.2 Non-Functional Requirements
   - 3.3 Hardware Requirements
   - 3.4 Software Requirements
4. [System Design](#4-system-design)
   - 4.1 Architecture Diagram
   - 4.2 Use Case Diagram
   - 4.3 Activity Diagram / Flowchart
   - 4.4 Database Design
   - 4.5 UI Design
5. [Implementation / Development](#5-implementation--development)
   - 5.1 Tools & Technologies
   - 5.2 Module Description
   - 5.3 Key Code Snippets
6. [Testing](#6-testing)
   - 6.1 Testing Strategy
   - 6.2 Bugs Found & Fixes
7. [Results and Discussion](#7-results-and-discussion)
8. [Conclusion and Future Work](#8-conclusion-and-future-work)
   - 8.1 Conclusion
   - 8.2 Future Enhancements

---

## 1. Introduction

### 1.1 Project Overview

FarReach is a tourism discovery and planning application focused on Bangladesh. The app allows users to explore tourist destinations categorised by type (Nature, Beach, Hills, History, Island, Lake, etc.) and budget level (Low, Mid, High). Each destination includes a rich detail page with description, historical background, real-time weather, trip-date weather forecast, safety and emergency information, hotel suggestions, local guide contacts, user reviews, booking management, and PDF-export of booking confirmations.

The project is named **FarReach** to evoke the idea of reaching far-flung, beautiful corners of Bangladesh that travellers might not otherwise discover. The package name used in the Flutter project is `farreach`.

### 1.2 Problem Statement

Tourism in Bangladesh suffers from a fragmented information ecosystem. Travellers commonly face:

- Scattered, unreliable information about destinations spread across multiple websites, travel blogs, and social media pages.
- No single app that covers discovery, weather, safety, local guides, and booking together.
- Lack of offline access, making planning difficult in areas with poor connectivity.
- No AI-driven itinerary planning for multi-day trips.
- Inadequate emergency information for travellers in unfamiliar locations.

FarReach was built to solve all of these problems in one coherent, well-designed application.

### 1.3 Objectives / Goals

The primary objectives of the FarReach project are:

1. **Catalogue** all major tourist spots in Bangladesh with rich descriptions, images, location data, and category tags.
2. **Enable discovery** through full-text search, category filters, and budget filters.
3. **Provide real-time and forecast weather** for every destination to help users plan travel dates.
4. **Support bookings** — hotel, guide, or package — with confirmation and cancellation workflows.
5. **Generate AI trip plans** using Google Gemini, taking into account trip length, traveller count, budget, origin city, and interests.
6. **Embed safety information** including national emergency hotlines (police, ambulance, fire, women's helpline) and location-specific safety tips.
7. **Offer an AI chat assistant** (FarReach Guide) for natural-language Q&A about destinations, weather, budget, and booking.
8. **Work offline** using a built-in fallback catalogue and locally cached data, with graceful degradation.
9. **Adapt to screen sizes** — phone, tablet, and desktop — using Material 3's NavigationBar and NavigationRail layouts.

### 1.4 Scope of the Project

The FarReach project covers:

- An Android mobile application (Flutter) with responsive layout support for phones and tablets.
- A backend REST API (Node.js + Express) serving destinations, authentication, weather, chat, trip planning, bookings, reviews, and hotel recommendations.
- A MySQL relational database for persistent data storage.
- Firebase integration for email/password authentication and Firebase Cloud Messaging (FCM) for push notifications.
- An admin panel (web) for managing spots, users, bookings, and reviews (served by the same Node.js server).
- Offline fallback: a built-in list of 10 curated Bangladesh destinations is bundled in the app binary and served when no network is available.
- PDF generation for booking confirmations.

The scope **does not** include an iOS or web deployment in this release, payment gateway integration, or real-time map routing.

### 1.5 Target Users

| User Type | Description |
|---|---|
| **Domestic Travellers** | Bangladeshi citizens exploring their own country's destinations. |
| **International Tourists** | Foreign visitors looking for curated guidance on Bangladesh tourism. |
| **Travel Groups** | Families or friend groups using the trip planner for multi-day itineraries. |
| **Solo Backpackers** | Budget-conscious travellers using the Low/Mid budget filters and offline guide. |
| **Administrators** | App maintainers who manage the destination catalogue, user accounts, and bookings through the admin web panel. |

### 1.6 Limitations

- **No real-time map integration within the app.** The Spots screen shows a list of geolocated destinations and opens an external map app (via `geo:` URI) for navigation — an in-app map widget is not yet implemented.
- **Hotel and guide data is partially fallback-generated.** When the server is unavailable, placeholder hotels and locally seeded guides are shown rather than live data.
- **AI replies require server connectivity.** The Gemini-backed `/api/chat` and `/api/planner` endpoints require a live server and valid API key; a local fallback reply is used when the server is unreachable.
- **Email OTP for registration depends on a configured SMTP provider.** Without a configured nodemailer transport, OTP emails are not sent (a preview code is returned in development mode only).
- **iOS support not built.** The project structure includes iOS scaffolding from Flutter, but the app is built and tested for Android only.

---

## 2. Literature Review / Related Work

Bangladesh is home to the world's longest unbroken sea beach, the largest mangrove forest on Earth, cloud-wrapped hill tracts inhabited by diverse Indigenous communities, and Mughal-era monuments that tell four centuries of urban history — yet for years, discovering and planning visits to these places has meant cobbling together scattered blog posts, outdated government portals, and word-of-mouth recommendations. A traveller curious about Cox's Bazar might find a hotel listing on TripAdvisor, check the weather on a separate site, look up emergency numbers on yet another, and still have no reliable way to plan a multi-day itinerary that connects the beach to the Sundarbans or the tea hills of Srimangal. Existing platforms like Google Travel and Airbnb Experiences serve global audiences well, but they treat Bangladesh as an afterthought — offering generic search results with no local depth, no offline fallback for areas where mobile data is unreliable, and no understanding of the country's eight-division geography. Domestic alternatives such as Shohoz and Obhai focus narrowly on transport ticketing, while the government's "Visit Bangladesh" web portal, though well-intentioned, has not been updated with modern UX, real-time data, or any mobile application at all.

The gap became especially clear during our early research phase, when we surveyed five university students planning a group trip to the Chattogram Hill Tracts. Every one of them described the same frustrating loop: searching Facebook groups for recommendations, messaging strangers for guide contacts, and having no idea what the weather or road conditions would be on their chosen dates. None of the tools they used — TripAdvisor, Google Maps, WhatsApp groups — could answer the simple question "Is next Thursday a good day to visit Bandarban?" with a data-backed verdict. Academic literature on mobile tourism systems (Dickinson et al., 2014; Gavalas et al., 2014) consistently identifies context-awareness, offline capability, and personalised itinerary generation as the three pillars of an effective travel companion app, yet no existing solution for Bangladesh delivers all three. The rise of large language models, particularly Google's Gemini, opened a new possibility: an AI that could ingest a live catalogue of Bangladeshi destinations and produce a personalised, day-by-day trip plan in seconds — something no existing app offered.

FarReach was designed to close every gap uncovered in this review. Where TripAdvisor is global and shallow, FarReach is Bangladesh-specific and deep — every spot carries curated descriptions, historical narratives, GPS coordinates, district and division tags, budget categories, and locally relevant safety information. Where Google Travel requires constant connectivity, FarReach ships a built-in offline catalogue of ten flagship destinations and caches the full server catalogue on-device so travellers in low-signal hill tracts or remote islands are never left with a blank screen. Where no existing app offers intelligent planning, FarReach integrates Google Gemini to generate complete multi-day itineraries based on the traveller's origin city, budget, group size, and interests — drawing from the same live destination database the user browses. And where safety has always been an afterthought, FarReach embeds a per-destination emergency directory with one-tap calling to national hotlines (Police 999, Ambulance 199, Tourist Police, Women's Helpline 10921) and Google Maps search links for nearby hospitals and police stations. The combination of AI-powered planning, offline resilience, real-time weather with trip-day verdicts, and integrated safety makes FarReach a fundamentally different kind of tourism app — one built from the ground up for the realities of travelling in Bangladesh.

**Research references:**
- Dickinson, J.E. et al. (2014). "Tourism and the smartphone app: capabilities, emerging practice and scope in the travel domain." *Current Issues in Tourism*, 17(1), 84–101.
- Gavalas, D. et al. (2014). "Mobile recommender systems in tourism." *Journal of Network and Computer Applications*, 39, 319–333.
- Material Design 3 guidelines (m3.material.io) — used for all UI/UX design decisions.
- Open-Meteo API documentation — used for weather forecast integration.
- Google Gemini API documentation — used for AI chat and trip planner endpoints.
- Firebase Documentation — used for Authentication and Cloud Messaging integration.
- Flutter official documentation (docs.flutter.dev) — primary SDK reference.

---

## 3. Requirement Analysis

### 3.1 Functional Requirements

| ID | Requirement |
|---|---|
| FR-01 | The app shall display a browsable list of tourist destinations fetched from the backend API. |
| FR-02 | The app shall provide full-text search across destination name, district, division, and category. |
| FR-03 | The app shall allow filtering destinations by category (All, Nature, Beach, Hills, History, etc.) and budget (Low, Mid, High). |
| FR-04 | Tapping a destination shall open a detail screen with description, history, location, images, weather, safety, hotels, guides, reviews, and booking. |
| FR-05 | The app shall display real-time weather (temperature, description, humidity, wind) for the destination's district. |
| FR-06 | The app shall display a forecast for a user-selected date, with a "Good to go" or "Use caution" verdict. |
| FR-07 | Users shall be able to save (favourite) destinations persistently, with sync to the backend for authenticated users. |
| FR-08 | Authenticated users shall be able to create bookings (hotel, guide, or package) for a destination with a date, person count, and optional package name. |
| FR-09 | Authenticated users shall be able to cancel bookings (not within 24 hours of the booking date). |
| FR-10 | The app shall provide an AI trip planner that generates a day-by-day itinerary based on user inputs (trip length, travellers, budget, origin, interests, notes). |
| FR-11 | The app shall provide an AI guide chat interface for natural-language queries about destinations, weather, budget, and booking. |
| FR-12 | The app shall show a safety and emergency sheet per destination, with national hotlines and local help search links. |
| FR-13 | The app shall allow user registration via email OTP verification and sign-in via email/password. |
| FR-14 | Firebase Authentication shall be supported as an alternative sign-in path. |
| FR-15 | Authenticated users shall be able to update their profile (name, phone, address, profile picture) and change their password. |
| FR-16 | The app shall allow PDF export of booking confirmations. |
| FR-17 | The app shall show recently viewed destinations on the Explore screen. |
| FR-18 | The app shall operate in offline mode, using the built-in fallback catalogue and locally cached data. |
| FR-19 | The Spots screen shall display all geolocated destinations and allow opening directions in an external map app. |
| FR-20 | An admin web panel shall allow managing spots, users, bookings, and reviews. |

### 3.2 Non-Functional Requirements

| Category | Requirement |
|---|---|
| **Performance** | The app shall load the destination list within 2 seconds on a standard 4G connection. API calls use a 15-second timeout. |
| **Usability** | UI follows Material Design 3 with responsive layouts (phone: NavigationBar, tablet/desktop: NavigationRail). |
| **Offline support** | The app shall display a built-in fallback catalogue of 10 destinations when the server is unreachable. The last fetched catalogue is cached in `SharedPreferences`. |
| **Security** | Passwords are hashed with bcrypt (salt rounds = 10). Session tokens are stored in device Keystore via `flutter_secure_storage`. Bearer token authentication is used for all API calls requiring auth. OTP verification is required for email registration. |
| **Accessibility** | Semantic labels are applied to key UI elements. Text scaling up to 1.3× is accommodated with adaptive layouts. |
| **Scalability** | The Node.js server uses connection pooling (mysql2) and stateless JWT-style tokens for horizontal scaling. |
| **Data integrity** | Foreign key constraints and CHECK constraints are defined in MySQL (e.g., `persons BETWEEN 1 AND 20`, `rating BETWEEN 1 AND 5`). |
| **Maintainability** | The Flutter app follows a clear layered structure: `models/`, `services/`, `state/`, `screens/`, `widgets/`, `theme/`. The server uses a single `index.js` with middleware separation. |

### 3.3 Hardware Requirements

| Item | Minimum Specification |
|---|---|
| **Android device** | Android 6.0 (API level 23) or higher |
| **RAM** | 2 GB or more |
| **Storage** | 50 MB free for app installation |
| **Network** | Wi-Fi or mobile data (for live features); offline mode available |
| **Development machine** | macOS / Windows / Linux, 8 GB RAM recommended |
| **Android emulator** | API 33+ (Tiramisu) with Google Play Services for Firebase testing |

### 3.4 Software Requirements

| Component | Details |
|---|---|
| **Flutter SDK** | v3.x (Dart SDK ^3.12.2) |
| **Android SDK** | API level 23 (minSdk) to API 36 (targetSdk / compileSdk) |
| **Node.js** | v18+ |
| **MySQL** | 8.0+ (database: `torisom_db`) |
| **Firebase** | Firebase Auth v6.7.0, Firebase Messaging v16.7.0, Firebase Core v4.15.0 |
| **Key Flutter packages** | `http ^1.5.0`, `shared_preferences ^2.5.3`, `flutter_secure_storage ^9.2.4`, `url_launcher ^6.3.2`, `pdf ^3.11.10`, `printing ^5.14.2` |
| **Key server packages** | `express ^4.19.2`, `mysql2 ^3.22.3`, `bcrypt ^6.0.0`, `nodemailer ^9.0.5`, `multer ^2.2.0`, `dotenv ^16.4.5` |
| **External APIs** | Google Gemini API (chat + trip planner), Open-Meteo API (weather forecast) |
| **IDE** | Android Studio / VS Code with Flutter and Dart plugins |

---

## 4. System Design

### 4.1 Architecture Diagram

FarReach uses a **layered client-server architecture**. The Flutter app communicates with the Node.js REST API over HTTP/HTTPS. Firebase is used as a secondary authentication provider with token exchange to the Node.js session system.

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter App (Android)                        │
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────────┐  │
│  │ Screens  │  │ Widgets  │  │  State   │  │    Theme       │  │
│  │ (UI)     │  │          │  │ (AppCtrl)│  │ (AppTheme)     │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────────────────┘  │
│       └─────────────┴─────────────┘                             │
│                      │                                           │
│  ┌────────────────────▼────────────────────────┐                │
│  │              Services Layer                  │                │
│  │  ApiClient  │  FirebaseService  │ TokenStore │                │
│  └──────────────────┬─────────────┬────────────┘                │
└─────────────────────┼─────────────┼────────────────────────────-┘
                       │             │
              HTTP/HTTPS           Firebase SDK
                       │             │
       ┌───────────────▼─────┐   ┌──▼──────────────────┐
       │   Node.js / Express │   │  Firebase (Google)   │
       │       API Server    │   │  - Auth              │
       │  /api/spots         │   │  - FCM Push          │
       │  /api/auth/*        │   └─────────────────────-┘
       │  /api/chat          │
       │  /api/planner       │
       │  /api/weather       │
       │  /api/bookings      │
       └──────────┬──────────┘
                  │
       ┌──────────▼──────────────────────────┐
       │           MySQL Database             │
       │  users │ spots │ bookings │ reviews  │
       │  saved_spots │ guides │ districts    │
       │  divisions │ otp_verifications       │
       └──────────────────────────────────────┘
                  │
       ┌──────────▼──────────────────────────┐
       │       External APIs                  │
       │  Google Gemini API  (AI chat/plan)   │
       │  Open-Meteo API    (weather forecast)│
       └──────────────────────────────────────┘
```

**App internal architecture** follows a simplified **MVC/ChangeNotifier** pattern:
- **Model** — `Destination`, `WeatherInfo`, `WeatherForecast`, `Booking`, `AppUser`, `Review`, `HotelRecommendation` (all in `lib/models/`)
- **Controller** — `AppController` extends `ChangeNotifier`, holds all app state and business logic
- **View** — Screens and Widgets rebuild reactively via `AnimatedBuilder(animation: controller, ...)`

### 4.2 Use Case Diagram

```
                          ┌───────────────────────────────────────────┐
                          │                FarReach App                │
                          │                                            │
  ┌────────────┐           │  ┌─────────────────────────────────────┐  │
  │   Guest    │◄──────────┤  │ UC-01: Browse & search destinations │  │
  │   User     │           │  └─────────────────────────────────────┘  │
  └─────┬──────┘           │  ┌─────────────────────────────────────┐  │
        │                  │  │ UC-02: Filter by category / budget  │  │
        │                  │  └─────────────────────────────────────┘  │
        │                  │  ┌─────────────────────────────────────┐  │
        │                  │  │ UC-03: View destination details      │  │
        │                  │  └─────────────────────────────────────┘  │
        │                  │  ┌─────────────────────────────────────┐  │
        │                  │  │ UC-04: Check weather & forecast      │  │
        │                  │  └─────────────────────────────────────┘  │
        │                  │  ┌─────────────────────────────────────┐  │
        │                  │  │ UC-05: Save/unsave destinations      │  │
        │                  │  └─────────────────────────────────────┘  │
        │                  │  ┌─────────────────────────────────────┐  │
        │                  │  │ UC-06: View safety & emergency info  │  │
        │                  │  └─────────────────────────────────────┘  │
        │                  │  ┌─────────────────────────────────────┐  │
        │                  │  │ UC-07: Use AI guide chat             │  │
        │                  │  └─────────────────────────────────────┘  │
        │                  │  ┌─────────────────────────────────────┐  │
        │                  │  │ UC-08: Use AI trip planner           │  │
        │                  │  └─────────────────────────────────────┘  │
        │                  │                                            │
        │  ┌───────────┐   │  ┌─────────────────────────────────────┐  │
        └──► Registered │◄──┤  │ UC-09: Register with email OTP      │  │
           │   User    │   │  └─────────────────────────────────────┘  │
           └─────┬─────┘   │  ┌─────────────────────────────────────┐  │
                 │          │  │ UC-10: Sign in / Firebase auth       │  │
                 │          │  └─────────────────────────────────────┘  │
                 │          │  ┌─────────────────────────────────────┐  │
                 │          │  │ UC-11: Create & manage bookings      │  │
                 │          │  └─────────────────────────────────────┘  │
                 │          │  ┌─────────────────────────────────────┐  │
                 │          │  │ UC-12: Write & view reviews          │  │
                 │          │  └─────────────────────────────────────┘  │
                 │          │  ┌─────────────────────────────────────┐  │
                 │          │  │ UC-13: Export booking as PDF         │  │
                 │          │  └─────────────────────────────────────┘  │
                 │          │  ┌─────────────────────────────────────┐  │
                 │          │  │ UC-14: Update profile & password     │  │
                 │          │  └─────────────────────────────────────┘  │
                 │          │                                            │
           ┌─────▼──────┐  │  ┌─────────────────────────────────────┐  │
           │   Admin    │◄──┤  │ UC-15: Manage spots/users/bookings  │  │
           └────────────┘  │  └─────────────────────────────────────┘  │
                           └───────────────────────────────────────────┘
```

### 4.3 Activity Diagram / Flowchart

**Main App Flow:**

```
App Launch
    │
    ▼
Initialize Firebase & AppController
    │
    ├── Load cached destinations (SharedPreferences)
    ├── Load saved spot names (guest or authenticated)
    ├── Restore recently viewed history
    │
    ▼
Render AppShell (NavigationBar / NavigationRail)
    │
    ├─── Tab 0: ExploreScreen
    │        │
    │        ├── Fetch /api/spots (refresh)
    │        ├── Search & Category filter
    │        └── Tap destination → DestinationDetailScreen
    │                │
    │                ├── Load weather (/api/weather)
    │                ├── Pick forecast date (/api/forecast via Open-Meteo)
    │                ├── Save / unsave (heart icon)
    │                ├── Booking sheet → POST /api/bookings
    │                ├── Safety sheet → show hotlines
    │                └── Reviews, Hotels, Local Guides
    │
    ├─── Tab 1: MapScreen (Spots)
    │        │
    │        └── List all geolocated spots → open map app
    │
    ├─── Tab 2: SavedScreen
    │        │
    │        └── Show saved destinations → open detail
    │
    └─── Tab 3: ProfileScreen
             │
             ├── Not signed in → Sign in / Register form
             │       ├── Sign in: POST /api/auth/login
             │       └── Register: POST /api/auth/signup/start → OTP → /complete
             │
             └── Signed in → Profile & Trips
                     ├── Bookings list (GET /api/user/bookings)
                     ├── Cancel booking (DELETE /api/user/bookings/:id)
                     ├── PDF export
                     └── Edit profile / change password
```

**User Registration Flow:**

```
Enter Name + Email + Password + Confirm Password
    │
    ▼
POST /api/auth/signup/start
    │
    ├── Validation: email format, password ≥ 8 chars
    ├── OTP generated (6-digit, bcrypt-hashed), stored in otp_verifications
    └── OTP sent via email (nodemailer)
    │
    ▼
User enters OTP code
    │
    ▼
POST /api/auth/signup/complete
    │
    ├── Verify OTP hash and expiry (10 minutes)
    ├── Create user record (bcrypt-hashed password)
    └── Return session token + user profile
```

### 4.4 Database Design

The database (`torisom_db`) uses MySQL 8.0+ with InnoDB engine and `utf8mb4` charset. The entity-relationship structure is:

```
divisions ──< districts ──< spots >── saved_spots >── users
                                 │                    │
                                 └──> bookings ───────┘
                                 │
                                 └──> reviews ─────── users
                                 │
                                 └──> guides

users ──────────────────── otp_verifications
users ──────────────────── otp_attempt_limits
```

**Table Descriptions:**

| Table | Key Columns | Purpose |
|---|---|---|
| `users` | id, name, email, password_hash, is_verified, role, phone, address, profile_pic | Stores user accounts. `role` is `user` or `admin`. |
| `spots` | id, name, district_id, division_id, category, description, history, image, budget_category, latitude, longitude | Main destination catalogue. |
| `divisions` | id, name | 8 divisions of Bangladesh. |
| `districts` | id, name, division_id | Districts, linked to their division. |
| `bookings` | id, user_id, spot_id, type, target_name, price, booking_date, persons, status | Booking records. `status` is `pending`, `confirmed`, or `cancelled`. |
| `reviews` | id, user_id, spot_id, rating (1–5), text, admin_reply | User reviews with optional admin reply. |
| `saved_spots` | id, user_id, spot_id | Tracks which spots each user has saved. Unique on (user_id, spot_id). |
| `guides` | id, name, spot_id, experience, rating, languages, specialties, price, contact | Local guide records linked to spots. |
| `otp_verifications` | id, email, otp (hashed), expires_at, verified | OTP records for email registration. Expires in 10 minutes. |
| `otp_attempt_limits` | email, failed_attempts, window_start, blocked_until | Rate-limiting table for OTP verification to prevent brute force. |

### 4.5 UI Design

FarReach uses **Material Design 3** with a teal/green seed colour (`#006B52`), rounded corners (18 dp), and an elevated, clean typographic hierarchy.

**Screen Overview:**

| Screen | Description |
|---|---|
| **Explore** | Hero banner with destination image, search bar, category filter chips, recently viewed horizontal scroll, and responsive grid of destination cards (1/2/3 columns based on screen width). |
| **Destination Detail** | Full-bleed image header with category label and name, then sections: Description & History, Weather (current + forecast date picker with verdict), Budget Estimator, Available Services (Hotels, Transports, Guiders, Others with web booking links), FarReach Booking Confirmation, Reviews, Safety Sheet. |
| **Spots (Map)** | Division-grouped list of all destinations with thumbnail, name, location, category, and a "Directions" icon button that opens the native map app. |
| **Saved** | Vertically scrollable list of saved destinations with thumbnail and quick-open. |
| **Profile** | Unauthenticated: segmented button toggle between Sign In / Create Account forms. Authenticated: profile header, bookings list with PDF export, edit profile sheet. |
| **AI Trip Planner** | Modal bottom sheet with steppers (days, travellers), dropdowns (origin, budget), interest chip selection, free-text notes, and AI-generated itinerary display with matched destination suggestions. |
| **FarReach Guide (Chat)** | Full-screen chat UI with message bubbles, typing indicator, and smart navigation shortcuts embedded in replies. |
| **Safety Sheet** | Per-destination modal bottom sheet with national emergency hotlines (call button), local services search (Google Maps), and destination-specific safety tips. |

---

## 5. Implementation / Development

### 5.1 Tools & Technologies

| Tool / Technology | Role |
|---|---|
| **Flutter 3.x (Dart)** | Cross-platform mobile app development framework |
| **Material Design 3** | UI design system (NavigationBar, NavigationRail, Cards, Chips) |
| **Node.js + Express** | Backend REST API server |
| **MySQL 8.0** | Relational database |
| **Firebase Auth** | Secondary email/password authentication path |
| **Firebase Cloud Messaging (FCM)** | Push notification delivery |
| **Google Gemini API** | AI-powered chat assistant and trip planner |
| **Open-Meteo API** | Free, no-key weather forecast API |
| **bcrypt** | Server-side password hashing |
| **flutter_secure_storage** | Secure storage of session tokens on device Keystore |
| **shared_preferences** | Local caching of destinations and recently viewed list |
| **http (Dart)** | HTTP client for API calls |
| **pdf + printing** | PDF generation and printing for booking confirmations |
| **nodemailer** | Email delivery for OTP registration |
| **multer** | Multipart file upload handling (profile pictures, spot images) |
| **Android Studio / VS Code** | Development IDE |

### 5.2 Module Description

#### Flutter App Modules

**`main.dart`**
Entry point. Initialises Firebase, creates `AppController`, and runs `FarReachApp`. The `AppController.initialize()` is called with `unawaited` so the UI renders immediately while data loads in the background.

**`AppController` (`state/app_controller.dart`)**
Central `ChangeNotifier` that manages all app state:
- Destination list (live from API + cache fallback)
- Saved destinations (guest: `SharedPreferences`; authenticated: synced to backend)
- Recently viewed history (last 12 destinations, persisted)
- User session (token + `AppUser` profile)
- Loading, offline, and error states
- Bookings list
- Exposes methods: `initialize()`, `refreshDestinations()`, `toggleSaved()`, `createBooking()`, `cancelBooking()`, `weatherFor()`, `forecastFor()`, `chatReply()`, `planTrip()`, `hotelsFor()`, `reviewsFor()`, `signIn()`, `register()`, `signOut()`, `signInWithFirebase()`

**`ApiClient` (`services/api_client.dart`)**
HTTP client wrapper over the `http` package:
- Resolves base URL from compile-time `API_BASE_URL` constant or falls back to `10.0.2.2:3000` (emulator) in debug mode.
- All requests include `Authorization: Bearer <token>` when authenticated.
- Provides typed methods for every API endpoint.
- Handles `TimeoutException` (15s), `FormatException`, and HTTP error status codes, translating all to `ApiFailure` with user-friendly messages.

**`FirebaseService` (`services/firebase_service.dart`)**
Singleton wrapper around `FirebaseAuth` and `FirebaseMessaging`:
- `initialize()` — sets up FCM background handler, requests notification permissions, fetches device token.
- `signUpWithEmail()` / `signInWithEmail()` / `signOut()` — Firebase Auth operations.
- `getIdToken()` — retrieves ID token for exchange with the Node.js backend.
- `getErrorMessage()` — translates Firebase error codes to human-readable strings.

**`ExploreScreen` (`screens/explore_screen.dart`)**
Main discovery screen with:
- `SliverAppBar` with expandable hero image, "FarReach" title, Trip Planner button, and Refresh button.
- Full-text search with real-time filtering.
- Category filter chips (dynamically generated from the destination catalogue).
- Recently viewed horizontal card scroll.
- Responsive grid (1 / 2 / 3 columns).
- Offline banner with retry button.

**`DestinationDetailScreen` (`screens/destination_detail_screen.dart`)**
Rich detail view, the most complex screen in the app. Sections include:
- Hero image header with category badge, name, location, save (heart) and safety buttons.
- Description & History expandable sections.
- Weather card (current conditions + date picker for forecast with verdict chip).
- Budget estimator (transport, lodging, food, and guide cost sliders with Bangladeshi Taka output, automatically redirecting upon completion to Available Services).
- Available Services page (categorized into Hotels, Travel Transports, Guiders, and Others with external web links for third-party reservations via Booking.com, Bangladesh Railway, Shohoz, GoZayaan, and BPC).
- Booking confirmation sheet (date picker, traveler stepper, package choice, 3-day lead time validation, storing reservation in FarReach backend).
- Local guides & traveler reviews (from `/api/reviews` or deterministic fallback).

**`TripPlannerSheet` (`widgets/trip_planner_sheet.dart`)**
Modal bottom sheet with:
- Day/traveller steppers, origin city dropdown, budget dropdown.
- Interest category chip multi-select (pulled from live destination categories).
- Free-text notes field.
- Calls `AppController.planTrip()` → `/api/planner` → Gemini.
- Shows AI-generated itinerary and a filtered list of matching destination suggestions.

**`SupportChatSheet` (`widgets/support_chat.dart`)**
In-app chat assistant:
- Maintains message history for multi-turn conversation context.
- Smart navigation shortcuts: mentions of "saved", "map", "profile", "account" navigate the user to the correct tab.
- Falls back to local canned responses if the server is unreachable.

**`SafetySheet` (`widgets/safety_sheet.dart`)**
Per-destination safety modal:
- National hotlines: Police (999), Ambulance (199), Fire (199), Women's Helpline (10921), Tourist Police (01769-690000).
- Division-specific advisory notes.
- "Find help near [destination]" with Google Maps search links for hospitals, police stations, etc.
- Safety tips list.

#### Node.js Server Modules

The entire server (`server/index.js`) is a single Express application covering:
- Authentication (`/api/auth/signup/start`, `/api/auth/signup/complete`, `/api/auth/login`, `/api/auth/logout`, `/api/auth/firebase`, `/api/auth/me`)
- Destination API (`GET /api/spots`, admin CRUD endpoints)
- Weather proxy (`GET /api/weather`)
- Gemini chat (`POST /api/chat`)
- Gemini trip planner (`POST /api/planner`)
- Booking management (`POST /api/bookings`, `GET /api/user/bookings`, `DELETE /api/user/bookings/:id`)
- Reviews (`POST /api/user/reviews`, `GET /api/spots/:id/reviews`, etc.)
- Hotels (`GET /api/hotels`)
- File uploads (profile pictures, spot images via multer)
- Static serving for the admin web panel

### 5.3 Key Code Snippets

#### Offline-First Data Loading (`AppController`)

```dart
Future<void> initialize() async {
  if (_initialized) return;
  _initialized = true;

  // Try to sign in from the persisted token before the first network call.
  await _restoreSession();

  final session = _captureSession();
  try {
    final destinations = await api.getDestinations();
    if (!_isCurrentSession(session)) return;
    _destinations = destinations.isNotEmpty ? destinations : _destinations;
    _offline = false;
    await _persistDestinations();
    _lastUpdated = DateTime.now();
  } on ApiFailure {
    _offline = true; // Silently fall back to cached/fallback data
  }

  if (isAuthenticated) await _syncSavedFromServer();
  if (isAuthenticated) await _loadBookings();
  _loading = false;
  notifyListeners();
}
```

#### Gemini-Backed Trip Planner (`ApiClient`)

```dart
Future<String> planTrip({
  required int days,
  required int travelers,
  required String budget,
  required String origin,
  required List<String> interests,
  required String notes,
  required List<Map<String, String>> catalog,
}) async {
  final payload = await _decode(
    () => _client.post(
      _uri('/api/planner'),
      headers: _headers,
      body: jsonEncode({
        'days': days, 'travelers': travelers, 'budget': budget,
        'origin': origin, 'interests': interests,
        'notes': notes, 'catalog': catalog,  // Live catalogue (up to 80 spots)
      }),
    ),
  );
  final plan = payload['plan']?.toString().trim() ?? '';
  if (plan.isEmpty) throw const ApiFailure('The trip planner did not return a plan.');
  return plan;
}
```

#### Secure Token Storage (`TokenStore`)

```dart
class SecureTokenStore implements TokenStore {
  const SecureTokenStore();
  static const _storage = FlutterSecureStorage();
  static const _key = 'farreach_session_token';

  @override Future<String?> read() => _storage.read(key: _key);
  @override Future<void> write(String token) =>
      _storage.write(key: _key, value: token);
  @override Future<void> clear() => _storage.delete(key: _key);
}
```

#### OTP Rate Limiting (Server)

```javascript
// Blocks an email for 30 minutes after 5 failed OTP attempts.
async function checkOtpAttemptLimit(email) {
  const [rows] = await db.query(
    'SELECT * FROM otp_attempt_limits WHERE email = ?', [email]
  );
  if (rows.length === 0) return { allowed: true };
  const record = rows[0];
  if (record.blocked_until && new Date() < new Date(record.blocked_until)) {
    const remaining = Math.ceil(
      (new Date(record.blocked_until) - new Date()) / 60000
    );
    return {
      allowed: false,
      message: `Too many failed attempts. Try again in ${remaining} minute(s).`,
    };
  }
  return { allowed: true };
}
```

#### Responsive Layout (`AppShell`)

```dart
// Uses NavigationBar on phones (<600dp) and NavigationRail on tablets/desktops.
return LayoutBuilder(
  builder: (context, constraints) {
    final useRail = constraints.maxWidth >= 600;
    final body = IndexedStack(index: _index, children: _pages);
    if (!useRail) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          destinations: _destinations,
          onDestinationSelected: (v) => setState(() => _index = v),
        ),
      );
    }
    return Scaffold(
      body: Row(children: [
        NavigationRail(
          selectedIndex: _index,
          extended: constraints.maxWidth >= 1100,
          onDestinationSelected: (v) => setState(() => _index = v),
        ),
        Expanded(child: body),
      ]),
    );
  },
);
```

---

## 6. Testing

### 6.1 Testing Strategy

FarReach uses a combination of automated widget tests and manual testing.

**Automated Widget Tests (`test/widget_test.dart`)**

Two widget tests are written using `flutter_test` and the `http` package's `MockClient`:

| Test | Description |
|---|---|
| `FarReach opens the offline Explore experience` | Creates an `AppController` with a mock HTTP client that returns an empty spots list. Verifies the app renders the Explore screen with the FarReach title, the "Explore Bangladesh" headline, the Cox's Bazar fallback card, and the Trip Planner button — all without throwing. |
| `Explore phone layout matches its visual baseline` | Sets the device size to 412×915 (phone), loads the app with the mock client, pre-caches the Cox's Bazar image, and runs a golden file test against `goldens/explore_phone.png` to catch visual regressions. |

**Manual Testing**

| Area | Test Cases |
|---|---|
| **Authentication** | Register with valid/invalid email, wrong OTP, expired OTP, correct OTP; sign in with correct/wrong password; Firebase sign-in; password reset. |
| **Offline mode** | Launch app with airplane mode on; verify fallback catalogue shown and offline banner displayed. |
| **Destination search** | Search for "cox", "dhaka", "sylhet", partial spellings; verify correct results returned. |
| **Category filter** | Select "Beach", "Nature", "Hills" and verify only matching cards shown; select "All" to clear. |
| **Booking** | Create booking for a destination; try date < 3 days ahead (should fail); cancel an upcoming booking; try to cancel within 24 hours (should fail). |
| **Weather** | View current weather on a destination detail page; select a date and verify forecast loads with verdict chip. |
| **Trip planner** | Enter 5 days, 3 travellers, Mid budget, Dhaka origin, Nature + Beach interests; verify AI returns a coherent itinerary. |
| **Safety sheet** | Open safety sheet for Bandarban; verify Police, Ambulance, Fire hotlines shown; tap Call button. |
| **Saved spots** | Save a destination as guest; close and reopen app; verify saved state persists. Sign in; verify saved list synced to backend. |
| **PDF export** | Create a booking; tap PDF icon; verify booking PDF opens in system viewer with correct details. |
| **Responsive layout** | Test on 360dp phone (NavigationBar shown), 800dp tablet (NavigationRail shown), 1200dp desktop (extended NavigationRail shown). |

### 6.2 Bugs Found & Fixes

| Bug | Description | Fix Applied |
|---|---|---|
| **Duplicate saved names after migration** | Legacy `farreach_saved_names_v1` key was read alongside the new `farreach_saved_names_guest_v2` key, causing duplicate entries after update. | Added a migration block in `_restoreLocalState()` that reads from the legacy key, writes to the new key, and deletes the legacy key on first run. |
| **Forecast crash on destinations without coordinates** | Calling the weather forecast API for a destination with `null` latitude/longitude caused an unhandled `ApiFailure`. | Added `hasCoordinates` guard in `ApiClient.getWeatherForecast()`; `FutureBuilder` in the detail screen shows a "forecast not available" message. |
| **FCM token retrieval error on some emulators** | `FirebaseMessaging.instance.getToken()` threw on emulators without Google Play Services. | Wrapped FCM token retrieval in a `try/catch` and silently swallowed the error (token is optional for core functionality). |
| **Booking cancellation within 24 hours not blocked** | The server accepted cancellations within 24 hours of the booking date. | Added `hoursUntilBooking <= 24` check in the `DELETE /api/user/bookings/:id` route and returns HTTP 400 with an informative message. |
| **OTP brute force vulnerability** | No rate limiting existed on OTP verification, allowing unlimited guesses. | Added `otp_attempt_limits` table and enforced a 30-minute block after 5 failed attempts within a 10-minute window. |
| **Image upload type bypass** | MIME type check alone was insufficient; a `.php` file renamed to `.jpg` passed the filter. | Added `originalExtension` check in `uploadFileFilter()` to verify both MIME type and file extension match an allowed pair. |
| **Cache key collision for destinations with id=0** | Offline fallback destinations all have `id: 0`, causing cache key collisions. | Changed `cacheKey` getter to use `name:<name>` when `id == 0` and `id:<id>` only when `id > 0`. |
| **Recently viewed shows stale image URLs** | After a destination's image was updated on the server, the recently viewed entry still showed the old URL. | `recentlyViewed` getter now resolves each stored entry against the live catalogue by `cacheKey` or normalized name before returning, ensuring fresh data is shown. |

---

## 7. Results and Discussion

### Final Working Output

FarReach v1.0.0 is a fully functional Android application that:

- **Loads and displays** a live catalogue of tourist destinations from the backend API, with an offline fallback catalogue of 10 curated spots when the network is unavailable.
- **Provides discovery** through real-time search, category chips, and recently viewed history.
- **Shows rich destination details** including real weather, trip-date forecast with a good-to-go verdict, budget estimation, and booking functionality.
- **Supports booking management** — creation, viewing, and cancellation — with PDF export of confirmations.
- **Delivers AI-generated trip plans** via Google Gemini in a conversational interface.
- **Embeds a safety directory** with national emergency hotlines and location-aware tips.
- **Adapts seamlessly** to phone, tablet, and desktop screen sizes.

### Performance Observations

| Metric | Observed Result |
|---|---|
| Cold start (first launch) | ~1.5 seconds to show the Explore screen (cached destinations load immediately; API fetch runs in background) |
| Destination list fetch (4G) | ~600–900 ms for the full catalogue |
| Weather load | ~300–500 ms (district-level, proxied through the Node.js server) |
| Forecast load | ~500 ms–1 s (direct Open-Meteo HTTPS call from the Flutter app) |
| AI trip plan | ~3–8 seconds (dependent on Gemini API latency) |
| Offline launch | Instant — fallback catalogue is in-memory; no I/O delay |
| Memory usage | ~110–130 MB on a mid-range Android device |

### What Went Well

- **Offline-first architecture** worked exactly as designed. Users in areas with poor connectivity can still browse the built-in catalogue and get safety information without any error screens.
- **Material 3 responsive layout** transitions smoothly between phone/tablet/desktop without any additional code per screen.
- **Firebase + custom backend hybrid authentication** was successfully implemented — users can sign in with either Firebase or the custom email/OTP system, and the app resolves both paths into a unified `AppUser` object.
- **AI trip planner** produces practical, well-formatted itineraries that match the available destinations and user preferences.
- **PDF export** was straightforward using the `pdf` and `printing` packages, and produces a professional-looking booking confirmation.

### What Could Have Been Done Better

- **Admin panel** was served as a static web page from the same Node.js server but could have been a separate Flutter web app for consistency.
- **Reviews and hotel data** rely partly on placeholder/fallback data when the server is unavailable; real hotel API integration would significantly improve usefulness.
- **In-app map** using `flutter_map` or the Google Maps Flutter plugin was planned but deferred due to time constraints.
- **Test coverage** is limited to two widget tests. A comprehensive test suite would improve reliability.

### User Feedback

Manual testing with a small group of 5 users (university students) revealed:
- All users found the UI **intuitive and visually appealing**.
- The **AI trip planner** was rated as the most exciting feature.
- Users requested a **notifications feature** to remind them of upcoming bookings (Firebase Cloud Messaging infrastructure is already in place for this).
- One user noted that the **budget estimator sliders** felt slightly disconnected from real pricing; real pricing data from hotels/guides API would improve this.

---

## 8. Conclusion and Future Work

### 8.1 Conclusion

The FarReach project successfully achieved all its primary objectives. A fully functional, offline-capable, AI-enhanced Bangladesh tourism explorer application was designed, implemented, and tested within the scope of CSE 4104. The app demonstrates strong engineering practices including:

- **Separation of concerns** (models, services, state, screens, widgets, theme).
- **Security** (bcrypt hashing, secure token storage, OTP verification, rate limiting, file upload type validation).
- **Offline resilience** (built-in fallback catalogue, `SharedPreferences` cache, graceful API failure handling).
- **Accessibility and responsiveness** (Material 3, responsive layouts, semantic labels).
- **AI integration** (Google Gemini for both conversational support and structured trip planning).

The project demonstrates how Flutter, Node.js, MySQL, and Firebase can be combined into a coherent full-stack mobile application, covering the full software development lifecycle from requirement analysis and system design to implementation, testing, and deployment.

### 8.2 Future Enhancements

| Enhancement | Priority | Description |
|---|---|---|
| **In-app map with clustering** | High | Integrate `flutter_map` (OSM tiles) or the Google Maps Flutter plugin to show all destinations on an interactive map with cluster markers. |
| **Push notification reminders** | High | Use the existing Firebase Cloud Messaging infrastructure to send booking reminders 24 hours and 1 hour before travel. |
| **Real hotel API integration** | High | Integrate with a hotel booking API (e.g., Agoda Partner or Expedia Affiliate) to show real availability and prices. |
| **Image gallery per destination** | Medium | Allow multiple images per spot (carousel view) instead of a single cover image. |
| **Offline AI replies** | Medium | Bundle a lightweight on-device model (e.g., Gemma via Google AI Edge) for offline chat responses. |
| **iOS deployment** | Medium | Build and test the Flutter app for iOS and publish to the App Store. |
| **Multi-language support** | Medium | Add Bengali (Bangla) language support using Flutter's `intl` and `flutter_localizations` packages. |
| **Comprehensive test suite** | Medium | Expand to full unit tests for `AppController` and `ApiClient`, integration tests for booking flow, and golden tests for all major screens. |
| **Payment gateway** | Low | Integrate bKash or Nagad (popular Bangladeshi mobile payment services) for in-app booking payments. |
| **Community reviews and photos** | Low | Allow users to upload photos with their reviews, and implement a moderation queue in the admin panel. |
| **AR destination preview** | Low (Future) | Use ARCore to show an augmented reality preview of a destination from GPS coordinates. |

---

*Report completed for FarReach v1.0.0 — Bangladesh Tourism Explorer.*  
*Course: CSE 4104 — Software Development Project II*
