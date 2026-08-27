import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository_impl.dart';
import '../domain/user.dart';

/// Holds the auth state for the whole app.
class AuthProvider extends ChangeNotifier {
  final AuthRepositoryImpl _repository;

  User? user;
  bool initialized = false;
  bool busy = false;
  String? error;

  AuthProvider({AuthRepositoryImpl? repository})
      : _repository = repository ?? AuthRepositoryImpl();

  bool get isLoggedIn => user != null;

  /// Restores the session (if any) on app start.
  Future<void> restoreSession() async {
    try {
      user = await _repository.currentUser();
    } catch (_) {
      user = null;
    } finally {
      initialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      user = await _repository.login(email: email, password: password);
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (_) {
      error = 'Could not reach the server. Is it running?';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    user = null;
    notifyListeners();
  }
}

