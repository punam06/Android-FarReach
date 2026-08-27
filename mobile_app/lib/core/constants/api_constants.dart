import 'package:flutter/foundation.dart' show kIsWeb;

/// Central API configuration for the app.
class ApiConstants {
  ApiConstants._();

  /// Base URL of the Express backend (server/index.js).
  /// Android emulators reach the host machine via 10.0.2.2;
  /// browsers/other platforms use localhost directly.
  static final String baseUrl =
      kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';


  // Auth
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';

  // Spots / destinations
  static const String spots = '/api/spots';

  // Bookings
  static const String bookings = '/api/user/bookings';
  static const String createBooking = '/api/bookings';

  // Reviews
  static const String reviews = '/api/reviews';

  /// Builds an absolute URL for images returned by the server
  /// (e.g. "/spot-pictures/Coxs bazar.jpg").
  static String imageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}

