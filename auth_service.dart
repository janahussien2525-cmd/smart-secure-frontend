import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';

const String _baseUrl = kIsWeb
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';

class AuthService {

  // ── REGISTER ──────────────────────────────────────────────
  static Future<void> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? nationalIdFront,
    String? nationalIdBack,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'email':     email,
        'phone':     phone,
        'password':  password,
        if (nationalIdFront != null) 'national_id_front': nationalIdFront,
        if (nationalIdBack  != null) 'national_id_back':  nationalIdBack,
      }),
    ).timeout(const Duration(seconds: 30));

    final body = jsonDecode(res.body);
    if (res.statusCode == 201) {
      AppState.token = body['token'];
      AppState.user  = body['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', body['token']);
      await prefs.setString('user',  jsonEncode(body['user']));
    } else {
      throw Exception(body['message'] ?? 'Registration failed.');
    }
  }

  // ── LOGIN ─────────────────────────────────────────────────
  static Future<void> signIn({
    required String identifier,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': identifier.contains('@') ? identifier.toLowerCase().trim() : identifier.trim(),
        'password':   password,
      }),
    ).timeout(const Duration(seconds: 10));

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      AppState.token = body['token'];
      AppState.user  = body['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', body['token']);
      await prefs.setString('user',  jsonEncode(body['user']));
    } else {
      throw Exception(body['message'] ?? 'Login failed.');
    }
  }

  // ── LOGOUT ────────────────────────────────────────────────
  static Future<void> signOut() async {
    AppState.token = '';
    AppState.user  = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // ── GET TOKEN ─────────────────────────────────────────────
  static Future<String> getToken() async {
    if (AppState.token.isNotEmpty) return AppState.token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  // ── HANDLE 401 — sign out and redirect to login ───────────
  static Future<void> handleUnauthorized(dynamic context) async {
    await signOut();
    if (context != null) {
      Navigator.of(context as BuildContext).pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  // ── IS LOGGED IN ──────────────────────────────────────────
  static Future<bool> isLoggedIn() async {
    if (AppState.token.isNotEmpty) return true;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('token') ?? '';
    if (saved.isNotEmpty) {
      AppState.token = saved;
      final userJson = prefs.getString('user');
      if (userJson != null) {
        AppState.user = jsonDecode(userJson) as Map<String, dynamic>;
      }
      return true;
    }
    return false;
  }
}
