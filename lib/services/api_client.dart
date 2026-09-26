import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/destination.dart';

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AppUser user;
}

class SignupStartResult {
  const SignupStartResult({required this.delivery, this.previewCode});

  final String delivery;
  final String? previewCode;
}

class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
    : baseUrl = _resolveBaseUrl(baseUrl),
      _client = client ?? http.Client();

  static const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _debugBaseUrl = 'http://10.0.2.2:3000';

  final String baseUrl;
  final http.Client _client;
  String? token;

  static String _resolveBaseUrl(String? override) {
    final candidate =
        (override ??
                (configuredBaseUrl.isNotEmpty
                    ? configuredBaseUrl
                    : (kReleaseMode ? '' : _debugBaseUrl)))
            .trim()
            .replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.tryParse(candidate);
    if (candidate.isEmpty ||
        uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        (kReleaseMode && uri.scheme != 'https')) {
      return '';
    }
    return candidate;
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token?.isNotEmpty == true) 'Authorization': 'Bearer $token',
  };

  Uri _uri(String path, [Map<String, String>? query]) {
    if (baseUrl.isEmpty) {
      throw const ApiFailure(
        'Live FarReach services are not configured for this build.',
      );
    }
    final uri = Uri.parse('$baseUrl$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _decode(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(const Duration(seconds: 15));
      Map<String, dynamic> payload = const {};
      if (response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) payload = Map<String, dynamic>.from(decoded);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = payload['error']?.toString().trim();
        throw ApiFailure(
          message?.isNotEmpty == true ? message! : 'Request failed',
          statusCode: response.statusCode,
        );
      }
      return payload;
    } on TimeoutException {
      throw const ApiFailure('The server took too long to respond.');
    } on FormatException {
      throw const ApiFailure('The server returned an unreadable response.');
    } on ApiFailure {
      rethrow;
    } catch (_) {
      throw const ApiFailure(
        'Could not reach FarReach. Check that the server is running.',
      );
    }
  }

  Future<List<Destination>> getDestinations() async {
    final payload = await _decode(
      () => _client.get(_uri('/api/spots'), headers: _headers),
    );
    final spots = payload['spots'];
    if (spots is! List) return const [];
    return spots
        .whereType<Map>()
        .map((item) => Destination.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<WeatherInfo> getWeather(String district) async {
    final payload = await _decode(
      () => _client.get(
        _uri('/api/weather', {'district': district}),
        headers: _headers,
      ),
    );
    return WeatherInfo.fromJson(payload);
  }

  Future<WeatherForecast> getWeatherForecast(
    Destination destination,
    DateTime date,
  ) async {
    if (!destination.hasCoordinates) {
      throw const ApiFailure('A forecast is unavailable for this destination.');
    }
    final day = date.toIso8601String().split('T').first;
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${destination.latitude}',
      'longitude': '${destination.longitude}',
      'daily': 'temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code',
      'timezone': 'auto',
      'start_date': day,
      'end_date': day,
    });
    final payload = await _decode(() => _client.get(uri, headers: _headers));
    return WeatherForecast.fromJson(payload, date);
  }

  Future<List<HotelRecommendation>> getHotels(
    Destination destination, {
    String? checkIn,
    String? checkOut,
  }) async {
    final payload = await _decode(
      () => _client.post(
        _uri('/api/hotels/search'),
        headers: _headers,
        body: jsonEncode({
          'city': destination.district,
          'destinationName': destination.name,
          'category': destination.category,
          'checkin': ?checkIn,
          'checkout': ?checkOut,
        }),
      ),
    );
    final hotels = payload['hotels'];
    if (hotels is! List) return const [];
    return hotels
        .whereType<Map>()
        .map(
          (item) =>
              HotelRecommendation.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<Review>> getReviews(int spotId) async {
    final payload = await _decode(
      () => _client.get(
        _uri('/api/reviews', {'spotId': '$spotId'}),
        headers: _headers,
      ),
    );
    final reviews = payload['reviews'];
    if (reviews is! List) return const [];
    return reviews
        .whereType<Map>()
        .map((item) => Review.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<AuthResult> login(String email, String password) async {
    final payload = await _decode(
      () => _client.post(
        _uri('/api/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ),
    );
    return _authResult(payload);
  }

  Future<SignupStartResult> startSignup(String name, String email) async {
    final payload = await _decode(
      () => _client.post(
        _uri('/api/auth/signup/start'),
        headers: _headers,
        body: jsonEncode({'name': name.trim(), 'email': email.trim()}),
      ),
    );
    return _signupStartResult(payload);
  }

  Future<SignupStartResult> resendSignup(String email) async {
    final payload = await _decode(
      () => _client.post(
        _uri('/api/auth/signup/resend'),
        headers: _headers,
        body: jsonEncode({'email': email.trim()}),
      ),
    );
    return _signupStartResult(payload);
  }

  SignupStartResult _signupStartResult(Map<String, dynamic> payload) {
    final code = payload['previewCode'] ?? payload['code'];
    return SignupStartResult(
      delivery: payload['delivery']?.toString() ?? 'email',
      previewCode: code?.toString(),
    );
  }

  Future<void> verifySignup(String email, String code) async {
    await _decode(
      () => _client.post(
        _uri('/api/auth/signup/verify-code'),
        headers: _headers,
        body: jsonEncode({'email': email.trim(), 'code': code.trim()}),
      ),
    );
  }

  Future<AuthResult> finishSignup({
    required String name,
    required String email,
    required String password,
  }) async {
    final payload = await _decode(
      () => _client.post(
        _uri('/api/auth/signup/set-password'),
        headers: _headers,
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        }),
      ),
    );
    return _authResult(payload);
  }

  AuthResult _authResult(Map<String, dynamic> payload) {
    final rawToken = payload['token']?.toString() ?? '';
    final rawUser = payload['user'];
    if (rawToken.isEmpty || rawUser is! Map) {
      throw const ApiFailure('Sign in response was incomplete.');
    }
    return AuthResult(
      token: rawToken,
      user: AppUser.fromJson(Map<String, dynamic>.from(rawUser)),
    );
  }

  Future<AppUser> getMe() async {
    final payload = await _decode(
      () => _client.get(_uri('/api/auth/me'), headers: _headers),
    );
    final rawUser = payload['user'];
    if (rawUser is! Map) throw const ApiFailure('Profile was unavailable.');
    return AppUser.fromJson(Map<String, dynamic>.from(rawUser));
  }

  Future<void> logout() async {
    await _decode(
      () => _client.post(_uri('/api/auth/logout'), headers: _headers),
    );
  }

  Future<List<Destination>> getSavedDestinations() async {
    final payload = await _decode(
      () => _client.get(_uri('/api/user/saved-spots'), headers: _headers),
    );
    final spots = payload['spots'];
    if (spots is! List) return const [];
    return spots
        .whereType<Map>()
        .map((item) => Destination.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveDestination(int spotId) async {
    await _decode(
      () => _client.post(
        _uri('/api/user/saved-spots'),
        headers: _headers,
        body: jsonEncode({'spot_id': spotId}),
      ),
    );
  }

  Future<void> removeSavedDestination(int spotId) async {
    await _decode(
      () => _client.delete(
        _uri('/api/user/saved-spots/$spotId'),
        headers: _headers,
      ),
    );
  }

  Future<Booking> createBooking({
    required int spotId,
    required String date,
    required int persons,
  }) async {
    final payload = await _decode(
      () => _client.post(
        _uri('/api/bookings'),
        headers: _headers,
        body: jsonEncode({
          'spot_id': spotId,
          'booking_date': date,
          'persons': persons,
        }),
      ),
    );
    final booking = payload['booking'];
    if (booking is! Map) throw const ApiFailure('Booking was not returned.');
    return Booking.fromJson(Map<String, dynamic>.from(booking));
  }

  Future<List<Booking>> getBookings() async {
    final payload = await _decode(
      () => _client.get(_uri('/api/user/bookings'), headers: _headers),
    );
    final bookings = payload['bookings'];
    if (bookings is! List) return const [];
    return bookings
        .whereType<Map>()
        .map((item) => Booking.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> cancelBooking(int id) async {
    await _decode(
      () => _client.delete(_uri('/api/user/bookings/$id'), headers: _headers),
    );
  }

  void close() => _client.close();
}
