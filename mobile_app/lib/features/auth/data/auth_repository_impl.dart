import '../../../core/network/api_client.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

/// REST implementation of [AuthRepository] backed by the Express API.
class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _client;

  AuthRepositoryImpl({ApiClient? client}) : _client = client ?? ApiClient.instance;

  @override
  Future<User> login({required String email, required String password}) async {
    final data = await _client.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );
    final token = data is Map ? data['token']?.toString() : null;
    if (token != null) await _client.saveToken(token);
    return User.fromJson((data as Map)['user'] as Map<String, dynamic>);
  }

  @override
  Future<User?> currentUser() async {
    if (await _client.token == null) return null;
    try {
      final data = await _client.get('/api/auth/me');
      final user = data is Map ? data['user'] : null;
      if (user is Map) return User.fromJson(user as Map<String, dynamic>);
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _client.clearToken();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post('/api/auth/logout');
    } finally {
      await _client.clearToken();
    }
  }
}

