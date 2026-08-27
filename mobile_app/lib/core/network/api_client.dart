import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

/// Exceptions used across the data layer.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Thin HTTP client wrapper around the Express backend.
///
/// Handles:
///  - JSON encoding/decoding
///  - attaching the `X-Session-Token` header (the server's auth scheme)
///  - persisting/restoring the session token via shared_preferences
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  static const String _tokenKey = 'session_token';

  String? _token;

  Future<String?> get token async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    return _token;
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && _token != null) headers['X-Session-Token'] = _token!;
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConstants.baseUrl}$path').replace(queryParameters: query);

  Future<dynamic> get(String path,
      {Map<String, String>? query, bool auth = true}) async {
    final response = await http.get(_uri(path, query),
        headers: _headers(auth: auth));
    return _handle(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await http.post(_uri(path),
        headers: _headers(), body: jsonEncode(body ?? {}));
    return _handle(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final response = await http.put(_uri(path),
        headers: _headers(), body: jsonEncode(body ?? {}));
    return _handle(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await http.delete(_uri(path), headers: _headers());
    return _handle(response);
  }

  dynamic _handle(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message = body is Map && body['error'] != null
        ? body['error'].toString()
        : 'Request failed (${response.statusCode})';
    throw ApiException(message, statusCode: response.statusCode);
  }
}

