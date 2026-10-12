import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/destination.dart';
import '../services/api_client.dart';
import '../services/firebase_service.dart';
import '../services/token_store.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.api,
    required this._preferences,
    required this._tokenStore,
  }) {
    _restoreLocalState();
  }

  static const _destinationCacheKey = 'farreach_destinations_v1';
  static const _legacySavedNamesKey = 'farreach_saved_names_v1';
  static const _guestSavedNamesKey = 'farreach_saved_names_guest_v2';
  static const _lastUpdatedKey = 'farreach_destinations_updated_at';
  static const _recentlyViewedKey = 'farreach_recently_viewed_v2';
  static const _recentlyViewedLimit = 12;

  final ApiClient api;
  final SharedPreferences _preferences;
  final TokenStore _tokenStore;

  List<Destination> _destinations = fallbackDestinations;
  final Set<String> _savedNames = {};
  List<Booking> _bookings = const [];
  List<Destination> _recentlyViewed = const [];
  AppUser? _user;
  DateTime? _lastUpdated;
  String? _lastError;
  bool _loading = true;
  bool _authBusy = false;
  bool _offline = false;
  bool _initialized = false;
  int _sessionGeneration = 0;

  List<Destination> get destinations => List.unmodifiable(_destinations);
  List<Booking> get bookings => List.unmodifiable(_bookings);
  AppUser? get user => _user;
  DateTime? get lastUpdated => _lastUpdated;
  String? get lastError => _lastError;
  bool get loading => _loading;
  bool get authBusy => _authBusy;
  bool get offline => _offline;
  bool get initialized => _initialized;
  bool get isAuthenticated =>
      _user != null &&
      (api.token?.isNotEmpty == true ||
          (FirebaseService.isInitialized &&
              FirebaseService.instance.currentUser != null));

  List<Destination> get savedDestinations => _destinations
      .where((destination) => isSaved(destination))
      .toList(growable: false);

  /// Recently opened destinations, resolved against the live catalog when
  /// possible so refreshed data (images, coordinates) stays current.
  List<Destination> get recentlyViewed {
    if (_recentlyViewed.isEmpty) return const [];
    final byKey = {for (final item in _destinations) item.cacheKey: item};
    final byName = {
      for (final item in _destinations) _normalizeName(item.name): item,
    };
    return _recentlyViewed
        .map(
          (item) =>
              byKey[item.cacheKey] ??
              byName[_normalizeName(item.name)] ??
              item,
        )
        .toList(growable: false);
  }

  static Future<AppController> create({ApiClient? api}) async {
    final preferences = await SharedPreferences.getInstance();
    return AppController(
      api: api ?? ApiClient(),
      preferences: preferences,
      tokenStore: const SecureTokenStore(),
    );
  }

  void _restoreLocalState() {
    final cached = _preferences.getString(_destinationCacheKey);
    if (cached != null) {
      try {
        final restored = Destination.decodeList(cached);
        if (restored.isNotEmpty) _destinations = restored;
      } catch (_) {
        // A corrupt cache should never prevent the built-in offline catalog.
      }
    }
    final guestNames = _preferences.getStringList(_guestSavedNamesKey);
    final legacyNames = _preferences.getStringList(_legacySavedNamesKey);
    _savedNames.addAll(
      (guestNames ?? legacyNames ?? const <String>[]).map(_normalizeName),
    );
    if (guestNames == null && legacyNames != null) {
      unawaited(
        _preferences.setStringList(
          _guestSavedNamesKey,
          _savedNames.toList()..sort(),
        ),
      );
      unawaited(_preferences.remove(_legacySavedNamesKey));
    }
    final updated = _preferences.getString(_lastUpdatedKey);
    _lastUpdated = updated == null ? null : DateTime.tryParse(updated);
    final recent = _preferences.getString(_recentlyViewedKey);
    if (recent != null) {
      try {
        _recentlyViewed = Destination.decodeList(recent);
      } catch (_) {
        // Ignore corrupt recent-history data.
      }
    }
  }

  /// Records that the traveler opened [destination] so it can appear in the
  /// "Recently viewed" row. Most-recent first, de-duplicated, capped.
  void recordDestinationView(Destination destination) {
    if (destination.name.trim().isEmpty) return;
    final key = destination.cacheKey;
    if (_recentlyViewed.isNotEmpty && _recentlyViewed.first.cacheKey == key) {
      return;
    }
    final next = <Destination>[
      destination,
      ..._recentlyViewed.where((item) => item.cacheKey != key),
    ];
    _recentlyViewed = next.length > _recentlyViewedLimit
        ? next.sublist(0, _recentlyViewedLimit)
        : next;
    unawaited(_persistRecentlyViewed());
    notifyListeners();
  }

  Future<void> _persistRecentlyViewed() {
    if (_recentlyViewed.isEmpty) {
      return _preferences.remove(_recentlyViewedKey);
    }
    return _preferences.setString(
      _recentlyViewedKey,
      Destination.encodeList(_recentlyViewed),
    );
  }

  Future<void> clearRecentlyViewed() async {
    if (_recentlyViewed.isEmpty) return;
    _recentlyViewed = const [];
    await _preferences.remove(_recentlyViewedKey);
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _loading = true;
    notifyListeners();

    if (FirebaseService.isInitialized &&
        FirebaseService.instance.currentUser != null) {
      final fbUser = FirebaseService.instance.currentUser!;
      try {
        await _exchangeFirebaseUser(fbUser);
      } catch (_) {
        // The API may be unreachable at launch. Keep the Firebase identity so
        // the user stays signed in and retry the exchange on the next action.
        final appUser = _appUserFromFirebase(fbUser);
        api.token = await FirebaseService.instance.getIdToken();
        _user = appUser;
        await _activateUserSavedScope(appUser);
      }
    } else {
      String? token;
      try {
        token = await _tokenStore.read();
      } catch (_) {
        // Corrupt or unrestorable secure storage must fail closed.
        try {
          await _tokenStore.clear();
        } catch (_) {
          // The app remains signed out even if the platform store is unavailable.
        }
      }
      if (token?.isNotEmpty == true) {
        api.token = token;
        try {
          await _activateUserSavedScope(await api.getMe());
          await Future.wait([_loadBookings(), _syncSavedWithServer()]);
        } on ApiFailure catch (error) {
          if (error.isUnauthorized) await _clearSession();
        }
      }
    }

    await refreshDestinations(silent: true);
    _loading = false;
    notifyListeners();
  }

  static AppUser _appUserFromFirebase(User user) {
    final email = user.email ?? '';
    final name =
        (user.displayName != null && user.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : (email.contains('@') ? email.split('@').first : 'Traveler');
    return AppUser(
      id: user.uid.hashCode.abs(),
      name: name,
      email: email,
      role: 'user',
    );
  }

  Future<void> refreshDestinations({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _lastError = null;
      notifyListeners();
    }
    try {
      final remote = await api.getDestinations();
      if (remote.isEmpty) {
        throw const ApiFailure('No destinations are available yet.');
      }
      _destinations = remote;
      _offline = false;
      _lastError = null;
      _lastUpdated = DateTime.now();
      await Future.wait([
        _preferences.setString(
          _destinationCacheKey,
          Destination.encodeList(remote),
        ),
        _preferences.setString(
          _lastUpdatedKey,
          _lastUpdated!.toIso8601String(),
        ),
      ]);
      if (isAuthenticated) unawaited(_syncSavedWithServer());
    } on ApiFailure catch (error) {
      _offline = true;
      _lastError = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  bool isSaved(Destination destination) =>
      _savedNames.contains(_normalizeName(destination.name));

  Future<bool> toggleSaved(Destination destination) async {
    final name = _normalizeName(destination.name);
    final adding = !_savedNames.contains(name);
    if (adding) {
      _savedNames.add(name);
    } else {
      _savedNames.remove(name);
    }
    await _persistSaved();
    notifyListeners();

    final session = _captureSession();
    if (session == null || destination.id <= 0) return false;
    try {
      if (adding) {
        await api.saveDestination(destination.id);
      } else {
        await api.removeSavedDestination(destination.id);
      }
      return true;
    } on ApiFailure catch (error) {
      if (!_isCurrentSession(session)) return false;
      if (error.isUnauthorized) await _clearSession();
      _lastError = 'Saved on this device. ${error.message}';
      notifyListeners();
      return false;
    }
  }

  Future<void> _syncSavedWithServer() async {
    final session = _captureSession();
    if (session == null) return;
    try {
      final remote = await api.getSavedDestinations();
      if (!_isCurrentSession(session)) return;
      final remoteNames = remote
          .map((item) => _normalizeName(item.name))
          .toSet();
      final locallySavedBeforeMerge = Set<String>.from(_savedNames);
      final mergedNames = {...locallySavedBeforeMerge, ...remoteNames};

      for (final name in locallySavedBeforeMerge.difference(remoteNames)) {
        if (!_isCurrentSession(session)) return;
        final matches = _destinations.where(
          (item) => _normalizeName(item.name) == name && item.id > 0,
        );
        if (matches.isNotEmpty) await api.saveDestination(matches.first.id);
      }
      if (!_isCurrentSession(session)) return;
      _savedNames
        ..clear()
        ..addAll(mergedNames);
      await _preferences.setStringList(
        _savedNamesKeyForUser(session.userId),
        mergedNames.toList()..sort(),
      );
      if (!_isCurrentSession(session)) return;
      notifyListeners();
    } on ApiFailure catch (error) {
      if (error.isUnauthorized && _isCurrentSession(session)) {
        await _clearSession();
      }
    }
  }

  Future<void> _persistSaved() async {
    await _preferences.setStringList(
      _activeSavedNamesKey,
      _savedNames.toList()..sort(),
    );
  }

  String get _activeSavedNamesKey =>
      _user == null ? _guestSavedNamesKey : _savedNamesKeyForUser(_user!.id);

  String _savedNamesKeyForUser(int userId) =>
      'farreach_saved_names_user_${userId}_v2';

  _SessionSnapshot? _captureSession() {
    final currentUser = _user;
    final currentToken = api.token;
    if (currentUser == null || currentToken?.isNotEmpty != true) return null;
    return _SessionSnapshot(
      generation: _sessionGeneration,
      userId: currentUser.id,
      token: currentToken!,
    );
  }

  bool _isCurrentSession(_SessionSnapshot session) =>
      session.generation == _sessionGeneration &&
      session.userId == _user?.id &&
      session.token == api.token;

  Set<String> _readSavedNames(String key) =>
      (_preferences.getStringList(key) ?? const <String>[])
          .map(_normalizeName)
          .toSet();

  Future<void> _activateUserSavedScope(AppUser user) async {
    final guestNames = Set<String>.from(_savedNames);
    final userNames = _readSavedNames(
      'farreach_saved_names_user_${user.id}_v2',
    );
    _sessionGeneration += 1;
    _user = user;
    _savedNames
      ..clear()
      ..addAll(userNames)
      ..addAll(guestNames);
    await Future.wait([
      _persistSaved(),
      _preferences.remove(_guestSavedNamesKey),
      _preferences.remove(_legacySavedNamesKey),
    ]);
  }

  void _activateGuestSavedScope() {
    _savedNames
      ..clear()
      ..addAll(_readSavedNames(_guestSavedNamesKey));
  }

  Future<void> login(String email, String password) async {
    _authBusy = true;
    _lastError = null;
    notifyListeners();
    try {
      if (FirebaseService.isInitialized) {
        final cred = await FirebaseService.instance.signInWithEmail(
          email: email,
          password: password,
        );
        final fbUser = cred.user;
        if (fbUser == null) throw Exception('No user returned from Firebase');
        await _signInFirebase(fbUser);
      } else {
        final result = await api.login(email, password);
        await _acceptAuth(result);
      }
    } catch (e) {
      if (FirebaseService.isInitialized) {
        _lastError = FirebaseService.getErrorMessage(e);
      } else {
        _lastError = e.toString();
      }
      rethrow;
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _authBusy = true;
    _lastError = null;
    notifyListeners();
    try {
      if (FirebaseService.isInitialized) {
        final cred = await FirebaseService.instance.signUpWithEmail(
          email: email,
          password: password,
          displayName: name,
        );
        final fbUser = cred.user;
        if (fbUser == null) throw Exception('No user returned from Firebase');
        await _signInFirebase(fbUser);
      } else {
        final result = await api.finishSignup(
          name: name,
          email: email,
          password: password,
        );
        await _acceptAuth(result);
      }
    } catch (e) {
      if (FirebaseService.isInitialized) {
        _lastError = FirebaseService.getErrorMessage(e);
      } else {
        _lastError = e.toString();
      }
      rethrow;
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    _authBusy = true;
    _lastError = null;
    notifyListeners();
    try {
      if (FirebaseService.isInitialized) {
        await FirebaseService.instance.sendPasswordResetEmail(email);
      }
    } catch (e) {
      if (FirebaseService.isInitialized) {
        _lastError = FirebaseService.getErrorMessage(e);
      } else {
        _lastError = e.toString();
      }
      rethrow;
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<void> resendFirebaseVerificationEmail() async {
    if (!FirebaseService.isInitialized) {
      throw const ApiFailure('Firebase authentication is not available.');
    }
    _authBusy = true;
    _lastError = null;
    notifyListeners();
    try {
      await FirebaseService.instance.sendEmailVerification();
    } catch (e) {
      _lastError = FirebaseService.getErrorMessage(e);
      rethrow;
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<void> _exchangeFirebaseUser(User fbUser) async {
    final idToken = await fbUser.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const ApiFailure('Your sign-in session could not be created.');
    }
    final result = await api.exchangeFirebaseToken(idToken);
    await _acceptAuth(result);
  }

  Future<void> _signInFirebase(User fbUser) async {
    try {
      await _exchangeFirebaseUser(fbUser);
    } on ApiFailure catch (error) {
      // A rejected token is a real failure, but an unreachable API should not
      // sign the user out. Keep the Firebase identity and retry later.
      if (error.isUnauthorized) rethrow;
      final appUser = _appUserFromFirebase(fbUser);
      api.token = await FirebaseService.instance.getIdToken();
      _user = appUser;
      await _activateUserSavedScope(appUser);
      notifyListeners();
    } catch (_) {
      final appUser = _appUserFromFirebase(fbUser);
      api.token = await FirebaseService.instance.getIdToken();
      _user = appUser;
      await _activateUserSavedScope(appUser);
      notifyListeners();
    }
  }

  Future<SignupStartResult> startSignup(String name, String email) async {
    _authBusy = true;
    notifyListeners();
    try {
      return await api.startSignup(name, email);
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<void> verifySignup(String email, String code) async {
    _authBusy = true;
    notifyListeners();
    try {
      await api.verifySignup(email, code);
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<SignupStartResult> resendSignup(String email) async {
    _authBusy = true;
    notifyListeners();
    try {
      return await api.resendSignup(email);
    } finally {
      _authBusy = false;
      notifyListeners();
    }
  }

  Future<void> finishSignup({
    required String name,
    required String email,
    required String password,
  }) async {
    await register(name: name, email: email, password: password);
  }

  Future<void> _acceptAuth(AuthResult result) async {
    api.token = result.token;
    await _tokenStore.write(result.token);
    await _activateUserSavedScope(result.user);
    await Future.wait([_loadBookings(), _syncSavedWithServer()]);
    notifyListeners();
  }

  Future<void> logout() async {
    if (FirebaseService.isInitialized) {
      try {
        await FirebaseService.instance.signOut();
      } catch (_) {}
    }
    final hadToken = api.token?.isNotEmpty == true;
    if (hadToken) {
      try {
        await api.logout();
      } catch (_) {
        // Local logout remains available if the server is offline.
      }
    }
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _sessionGeneration += 1;
    api.token = null;
    _user = null;
    _bookings = const [];
    _activateGuestSavedScope();
    await _tokenStore.clear();
  }

  Future<Booking> createBooking({
    required Destination destination,
    required DateTime date,
    required int persons,
  }) async {
    final session = _captureSession();
    if (session == null) throw const ApiFailure('Sign in to book this trip.');
    if (destination.id <= 0) {
      throw const ApiFailure(
        'Connect to FarReach and refresh destinations before booking.',
      );
    }
    final booking = await api.createBooking(
      spotId: destination.id,
      date: _dateOnly(date),
      persons: persons,
    );
    if (!_isCurrentSession(session)) {
      throw const ApiFailure(
        'Your account changed. Refresh bookings to continue.',
      );
    }
    _bookings = [booking, ..._bookings];
    notifyListeners();
    return booking;
  }

  Future<void> cancelBooking(int id) async {
    await api.cancelBooking(id);
    await _loadBookings();
    notifyListeners();
  }

  Future<void> _loadBookings() async {
    final session = _captureSession();
    if (session == null) return;
    try {
      final bookings = await api.getBookings();
      if (!_isCurrentSession(session)) return;
      _bookings = bookings;
    } on ApiFailure catch (error) {
      if (error.isUnauthorized && _isCurrentSession(session)) {
        await _clearSession();
      }
    }
  }

  Future<WeatherInfo> weatherFor(Destination destination) => api.getWeather(
    destination.district.isEmpty ? destination.division : destination.district,
  );

  Future<WeatherForecast> forecastFor(Destination destination, DateTime date) =>
      api.getWeatherForecast(destination, date);

  Future<String> chatReply(
    String message, {
    List<Map<String, String>> history = const [],
  }) => api.sendChatMessage(message: message, history: history);

  /// Asks the AI trip planner for a day-by-day itinerary using the live
  /// destination catalog as its shortlist.
  Future<String> planTrip({
    required int days,
    required int travelers,
    required String budget,
    required String origin,
    required List<String> interests,
    String notes = '',
  }) {
    final catalog = _destinations
        .take(80)
        .map(
          (destination) => {
            'name': destination.name,
            'district': destination.district.isEmpty
                ? destination.division
                : destination.district,
            'category': destination.category,
            'budget': destination.budget,
          },
        )
        .toList(growable: false);
    return api.planTrip(
      days: days,
      travelers: travelers,
      budget: budget,
      origin: origin,
      interests: interests,
      notes: notes,
      catalog: catalog,
    );
  }

  Future<List<HotelRecommendation>> hotelsFor(Destination destination) =>
      api.getHotels(destination);

  Future<List<Review>> reviewsFor(Destination destination) async {
    if (destination.id <= 0) return const [];
    return api.getReviews(destination.id);
  }

  static String _normalizeName(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      "cox's bazar" || "cox's bazar sea beach" => "cox's bazar sea beach",
      'the sundarbans' || 'sundarbans' => 'sundarbans',
      'srimangal tea country' ||
      'srimangal tea garden' => 'srimangal tea garden',
      _ => normalized,
    };
  }

  static String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    api.close();
    super.dispose();
  }
}

class _SessionSnapshot {
  const _SessionSnapshot({
    required this.generation,
    required this.userId,
    required this.token,
  });

  final int generation;
  final int userId;
  final String token;
}
