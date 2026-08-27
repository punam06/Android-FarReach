import 'user.dart';

/// Abstract contract for authentication operations.
abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<User?> currentUser();
  Future<void> logout();
}

