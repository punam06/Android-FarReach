# 🌏 FarReach — Bangladesh Tourism Explorer

A full-stack web and Flutter Android application for exploring tourist destinations across Bangladesh. Discover destinations, check weather, save places, book trips, and manage travel from a responsive Material 3 mobile experience or the existing web app.

![Node.js](https://img.shields.io/badge/Node.js-v18+-green?logo=node.js)
![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?logo=mysql)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## ✨ Features

### 🗺️ For Travelers
- **100+ Destinations** — Browse tourist spots across all 8 divisions of Bangladesh
- **Interactive Map** — Google Maps & Leaflet integration with clickable markers
- **Real-time Weather** — Current weather & forecasts via OpenWeather API
- **Trip Budget Calculator** — Estimate costs based on origin district, transport mode, persons & duration
- **Spot Booking** — Book travel packages directly from any destination page
- **Reviews & Ratings** — Submit reviews with star ratings; see admin responses
- **Save Favorites** — Save spots to your personal collection
- **Guide Directory** — Browse local tour guides with contact info, ratings & specialties
- **Category Filters** — Filter by Beach, Nature, History, Religious, Culture, Wetland, Ecotourism, City
- **Division Filters** — Filter destinations by division (Dhaka, Chattogram, Sylhet, etc.)

### 👤 User Dashboard
- **My Bookings** — View all bookings with status, cancel within 24h of travel date
- **My Reviews** — Edit or delete your reviews, see admin replies
- **Saved Spots** — Manage your saved destinations
- **Profile Settings** — Update name, phone, address, profile picture & password
- **Guide Directory** — View guides for your saved spots

### 🛡️ Admin Dashboard
- **Overview Stats** — Total users, spots, reviews, pending bookings at a glance
- **User Management** — Promote/demote admins, delete users with cascade protection
- **Spot Management** — Add, edit, delete tourist spots (changes reflect on main site in real-time)
- **Review Moderation** — View all reviews, reply to users, delete inappropriate content
- **Booking Management** — View all bookings, update statuses
- **Guide Management** — Add & manage local tour guides per spot

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Android app** | Flutter, Dart, Material 3 |
| **Frontend** | HTML5, CSS3, Vanilla JavaScript |
| **Backend** | Node.js, Express.js |
| **Database** | MySQL 8.0 |
| **Maps** | Google Maps API, Leaflet.js |
| **Weather** | OpenWeather API, Open-Meteo API |
| **Email** | Nodemailer (Gmail SMTP) |
| **Auth** | Server-side session tokens + OTP Email Verification |
| **File Upload** | Multer |

---

## 📁 Project Structure

```
FarReach-App/
├── index.html              # Main homepage
├── destination.html        # Destination detail page
├── destination.js          # Destination page logic
├── admin-dashboard.html    # Admin panel
├── user-dashboard.html     # User panel
├── dashboard.css           # Dashboard styles
├── script.js               # Main site logic (spots, map, filters)
├── auth.js                 # Authentication (login/signup/OTP)
├── styles.css              # Main site styles
├── .env                    # Root environment config
├── server/
│   ├── index.js            # Express server & all API routes
│   ├── db.js               # MySQL connection pool
│   ├── database.sql        # Database schema dump
│   ├── .env                # Server environment config
│   ├── .env.example        # Environment template
│   └── package.json        # Node.js dependencies
├── mobile/                 # Flutter Android app
│   ├── lib/                # UI, state, API client & local cache
│   ├── assets/images/      # Offline destination photography
│   ├── test/               # Model, API, widget & golden tests
│   └── android/            # Android Gradle project
└── spot-pictures/          # Uploaded spot images
```

---

## 🚀 Getting Started

### Prerequisites

- **Node.js** v18 or higher
- **MySQL** 8.0 or higher
- **npm** (comes with Node.js)
- **Flutter** stable and Android SDK (for the mobile app)
- **VS Code** with the Dart and Flutter extensions

### 1. Clone the Repository

```bash
git clone https://github.com/punam06/FarReach-App.git
cd FarReach-App
```

### 2. Set Up the Database

```bash
# Login to MySQL
mysql -u root -p

# Create the database
CREATE DATABASE torisom_db;
USE torisom_db;

# Import the schema
SOURCE server/database.sql;
```

### 3. Configure Environment Variables

```bash
# Copy the example env file
cp server/.env.example server/.env
```

Edit `server/.env` with your values:

```env
# Local-only OTP preview. Use production with working SMTP when deployed.
NODE_ENV=development

# Database
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=torisom_db

# Server
PORT=3000
APP_API_BASE_URL=http://127.0.0.1:3000

# Email (Gmail SMTP for OTP verification)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_gmail_app_password
SMTP_FROM=Bangladesh Tourism <your_email@gmail.com>

# API Keys
OPENWEATHER_API_KEY=your_openweather_key
GOOGLE_MAPS_API_KEY=your_google_maps_key
```

> **📝 Gmail App Password:** Go to [Google Account → Security → App Passwords](https://myaccount.google.com/apppasswords) to generate one. Regular passwords won't work with SMTP.

### 4. Install Dependencies

```bash
cd server
npm install
```

### 5. Start the Server

```bash
node index.js
```

The app will be running at **http://localhost:3000**

### 6. Run the Flutter Android App in VS Code

Open the `mobile` folder in VS Code, select an Android device, then run:

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

`10.0.2.2` reaches the host machine from the Android emulator. For a physical Android device, keep the phone and computer on the same network and replace it with the computer's LAN address, for example `http://192.168.0.10:3000`. The API server must be running and allowed through the firewall.

Release builds deliberately do not fall back to the emulator URL. Supply an explicit HTTPS endpoint, for example:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.example.com
```

Without that setting, the release app remains usable as an offline guide while live account, weather, hotel, and booking calls fail safely. Configure a private release keystore outside source control before publishing.

The app keeps a built-in Bangladesh destination catalog and local saved list, so browsing still works when the API is offline. Account sync, live weather, and booking require the API.

Run checks and build an installable debug APK with:

```bash
cd mobile
flutter analyze
flutter test
flutter build apk --debug
```

The APK is written to `mobile/build/app/outputs/flutter-apk/app-debug.apk`.

---

## 📖 How to Use

### Browsing Destinations
1. Open `http://localhost:3000` in your browser
2. Use the **category buttons** (Beach, Nature, History, etc.) to filter spots
3. Use the **division cards** to filter by region
4. Use the **search bar** to find specific destinations
5. Click any destination card to view its **detail page**

### Destination Detail Page
- 🌤️ **Weather** — See current conditions and pick a trip date for forecasts
- 🗺️ **Map** — Interactive map with Google Maps or Leaflet
- 🧭 **Travel Guide** — Tips, best time to visit, local guides
- 🏨 **Hotels** — Nearby accommodation with ratings and prices
- 📦 **Booking** — Pick a date, set persons, and confirm your booking
- 💰 **Budget Calculator** — Estimate total trip costs from your district
- ⭐ **Reviews** — Read and write reviews (requires login)

### User Account
1. Click **Login / Sign Up** on the homepage
2. Create an account with **email OTP verification**
3. Access your **User Dashboard** to manage bookings, reviews, saved spots

### Booking a Trip
1. Navigate to any destination's detail page
2. Scroll to **"Booking & Reservations"**
3. Select your travel date and number of persons
4. Click **"Confirm Booking"** (must be logged in)
5. View & cancel bookings from **User Dashboard → My Bookings**
6. Cancellation is free up to **24 hours before** the travel date

### Admin Panel
1. Login with an admin account
2. Navigate to `/admin-dashboard.html`
3. Manage spots, users, reviews, bookings, and guides

---

## 🔌 API Endpoints

### Public
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/spots` | List all spots from database |
| GET | `/api/spots/lookup?name=...` | Find spot by name |
| GET | `/api/reviews?destinationName=...` | Get reviews for a destination |
| GET | `/api/weather?district=...` | Current weather for a district |
| GET | `/api/forecast?district=...&date=...` | Weather forecast |
| POST | `/api/hotels/search` | Search hotels with `{city, destinationName, category, checkin, checkout}` |
| GET | `/api/site-content` | Site content & settings |

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/signup/start` | Start signup with `{name, email}` and send an OTP |
| POST | `/api/auth/signup/resend` | Send a new OTP for `{email}` |
| POST | `/api/auth/signup/verify-code` | Verify `{email, code}` |
| POST | `/api/auth/signup/set-password` | Complete signup with `{email, password, name}` |
| POST | `/api/auth/login` | Login with email & password |
| GET | `/api/auth/me` | Get the signed-in user |
| POST | `/api/auth/logout` | End the current session |

### User (Auth Required)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/user/dashboard` | Dashboard stats & recent activity |
| GET | `/api/user/saved-spots` | Saved spots list |
| POST | `/api/user/saved-spots` | Save `{spot_id}`; repeated requests are safe |
| DELETE | `/api/user/saved-spots/:id` | Remove saved spot |
| GET | `/api/user/reviews` | User's reviews |
| PUT | `/api/user/reviews/:id` | Edit a review |
| DELETE | `/api/user/reviews/:id` | Delete a review |
| GET | `/api/user/bookings` | User's bookings |
| DELETE | `/api/user/bookings/:id` | Cancel booking (24h rule) |
| GET | `/api/user/guides` | Guide directory |
| POST | `/api/bookings` | Book with `{spot_id, booking_date, persons}` (1-20 people); price is calculated by the server |
| PUT | `/api/auth/profile` | Update profile |

Send authenticated requests with `Authorization: Bearer <token>`. Session tokens are held in server memory, so users must sign in again after the API server restarts.

### Admin (Admin Auth Required)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/stats` | Dashboard statistics |
| GET | `/api/admin/spots` | All spots with details |
| POST | `/api/admin/spots` | Add new spot |
| PUT | `/api/admin/spots/:id` | Edit spot |
| DELETE | `/api/admin/spots/:id` | Delete spot |
| GET | `/api/admin/users` | All users |
| PUT | `/api/admin/users/:id/role` | Change user role |
| DELETE | `/api/admin/users/:id` | Delete user |
| GET | `/api/admin/reviews` | All reviews |
| DELETE | `/api/admin/reviews/:id` | Delete review |
| PUT | `/api/admin/reviews/:id/reply` | Reply to review |
| GET | `/api/admin/bookings` | All bookings |
| PUT | `/api/admin/bookings/:id/status` | Update booking status |

---

## 🗄️ Database Schema

| Table | Description |
|-------|-------------|
| `users` | User accounts (name, email, password, role, profile) |
| `spots` | Tourist destinations (name, district, category, coordinates) |
| `districts` | District names linked to divisions |
| `divisions` | 8 divisions of Bangladesh |
| `reviews` | User reviews with ratings (1-5 stars) |
| `bookings` | Trip bookings (package/hotel/guide) with status |
| `saved_spots` | User's saved/favorited destinations |
| `guides` | Local tour guides per spot |
| `otp_verifications` | Email OTP codes for signup |

---

## 👥 Authors

- **Punam Papri** — [GitHub](https://github.com/punam06)

---

## 📄 License

This project is licensed under the MIT License.
