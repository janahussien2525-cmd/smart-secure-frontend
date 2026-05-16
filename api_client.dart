import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'app_state.dart';
import 'auth_service.dart';
import 'main.dart' show navigatorKey;

const String baseUrl = kIsWeb
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

class ApiClient {
  static Future<String> _token() => AuthService.getToken();

  static Map<String, String> _headers(String token, {bool json = false}) => {
    'Authorization': 'Bearer $token',
    if (json) 'Content-Type': 'application/json',
  };

  static void _checkAuth(int statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      AppState.token = '';
      AppState.user  = null;
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final token = await _token();
    final res   = await http.get(Uri.parse('$baseUrl$path'),
        headers: _headers(token)).timeout(const Duration(seconds: 10));
    _checkAuth(res.statusCode);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final token = await _token();
    final res   = await http.post(Uri.parse('$baseUrl$path'),
        headers: _headers(token, json: true),
        body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    _checkAuth(res.statusCode);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final token = await _token();
    final res   = await http.put(Uri.parse('$baseUrl$path'),
        headers: _headers(token, json: true),
        body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    _checkAuth(res.statusCode);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final token = await _token();
    final res   = await http.delete(Uri.parse('$baseUrl$path'),
        headers: _headers(token)).timeout(const Duration(seconds: 10));
    _checkAuth(res.statusCode);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
