import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Central auth + demo-session manager.
/// Backed by SharedPreferences for JWT persistence (survives page refresh).
/// Demo session UUID is an in-memory static — cleared when the tab closes.
class AuthService extends ChangeNotifier {
  // ── Singleton ────────────────────────────────────────────────────────────
  static final AuthService instance = AuthService._();
  AuthService._();

  // ── State ────────────────────────────────────────────────────────────────
  AppUser? _user;
  String?  _token;
  bool     _isDemo = false;
  String?  _demoSessionId;
  bool     _initialized = false;

  // ── Getters ──────────────────────────────────────────────────────────────
  AppUser? get user            => _user;
  bool     get isLoggedIn      => _token != null;
  bool     get isDemo          => _isDemo;
  bool     get isAuthenticated => isLoggedIn || _isDemo;
  String?  get demoSessionId   => _demoSessionId;

  /// HTTP headers to attach to every API call.
  Map<String, String> get headers {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (_token != null)        h['Authorization'] = 'Bearer $_token';
    if (_demoSessionId != null) h['X-Demo-Session'] = _demoSessionId!;
    return h;
  }

  // ── Init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('auth_user');
    if (userJson != null) {
      try { _user = AppUser.fromJsonString(userJson); } catch (_) {}
    }
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> login(String email, String password, String baseUrl) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map;
      throw Exception(body['error'] ?? 'Login failed');
    }
    await _handleAuthResponse(res.body);
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<void> register(String name, String email, String password, String baseUrl) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body) as Map;
      throw Exception(body['error'] ?? 'Registration failed');
    }
    await _handleAuthResponse(res.body);
  }

  Future<void> _handleAuthResponse(String body) async {
    final data  = jsonDecode(body) as Map<String, dynamic>;
    _token = data['token'] as String;
    _user  = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    _isDemo = false;
    _demoSessionId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    await prefs.setString('auth_user',  _user!.toJsonString());
    notifyListeners();
  }

  // ── Demo Mode ─────────────────────────────────────────────────────────────
  void startDemo() {
    _demoSessionId = _generateUuid();
    _isDemo = true;
    notifyListeners();
  }

  /// Exits demo mode and deletes all demo projects from the backend.
  Future<void> exitDemo(String baseUrl) async {
    final sessionId = _demoSessionId;
    _isDemo = false;
    _demoSessionId = null;
    notifyListeners();
    if (sessionId != null) {
      try {
        await http.delete(
          Uri.parse('$baseUrl/projects/demo/$sessionId'),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (_) {} // Fire and forget
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _token = null;
    _user  = null;
    _isDemo = false;
    _demoSessionId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _generateUuid() {
    final rng = Random.secure();
    String hex(int n) => rng.nextInt(n).toRadixString(16).padLeft(2, '0');
    return '${hex(256)}${hex(256)}${hex(256)}${hex(256)}-'
        '${hex(256)}${hex(256)}-4${hex(64).padLeft(3, '0')}-'
        '${(rng.nextInt(4) + 8).toRadixString(16)}${hex(256).padLeft(3, '0')}-'
        '${hex(256)}${hex(256)}${hex(256)}${hex(256)}${hex(256)}${hex(256)}';
  }
}
