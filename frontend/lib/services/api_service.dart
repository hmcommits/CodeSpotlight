import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project_model.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static const Duration _timeout = Duration(seconds: 20);

  /// Auth + demo headers injected automatically from AuthService
  static Map<String, String> get _headers => AuthService.instance.headers;

  // ── GET /api/projects ───────────────────────────────────────────────────────
  static Future<List<Project>> getProjects({
    String? stack, String? language, String? search,
  }) async {
    final params = <String, String>{};
    if (stack != null && stack.isNotEmpty)    params['stack']    = stack;
    if (language != null && language.isNotEmpty) params['language'] = language;
    if (search != null && search.isNotEmpty)  params['search']   = search;

    final uri = Uri.parse('$baseUrl/projects').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = data['projects'] as List<dynamic>;
      return list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception((jsonDecode(res.body) as Map)['error'] ?? 'Failed to load projects');
  }

  // ── POST /api/projects ──────────────────────────────────────────────────────
  static Future<Project> submitProject(
    String githubUrl, {String liveUrl = '', String videoUrl = ''}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/projects'),
      headers: _headers,
      body: jsonEncode({'githubUrl': githubUrl, 'liveUrl': liveUrl, 'videoUrl': videoUrl}),
    ).timeout(_timeout);

    if (res.statusCode == 200 || res.statusCode == 202) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Project.fromJson(data['project'] as Map<String, dynamic>);
    }
    throw Exception((jsonDecode(res.body) as Map)['error'] ?? 'Failed to submit project');
  }

  // ── GET /api/projects/:id ───────────────────────────────────────────────────
  static Future<Project> getProjectById(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/projects/$id'), headers: _headers,
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      return Project.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Project not found');
  }

  // ── GET /api/projects/:id/poll ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> pollAiStatus(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/projects/$id/poll'), headers: _headers,
    ).timeout(_timeout);
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Failed to poll AI status');
  }

  // ── POST /api/projects/:id/heartbeat ────────────────────────────────────────
  static Future<String> checkHeartbeat(String id, String liveUrl) async {
    final res = await http.post(
      Uri.parse('$baseUrl/projects/$id/heartbeat'),
      headers: _headers,
      body: jsonEncode({'liveUrl': liveUrl}),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map)['status'] as String? ?? 'unknown';
    }
    return 'unknown';
  }

  // ── POST /api/projects/:id/reanalyze ────────────────────────────────────────
  static Future<void> reanalyze(String id) async {
    await http.post(
      Uri.parse('$baseUrl/projects/$id/reanalyze'),
      headers: _headers,
    ).timeout(_timeout);
  }

  // ── GET /api/projects/:id/commit-activity ────────────────────────────────────
  static Future<List<List<int>>> getCommitActivity(String id) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/projects/$id/commit-activity'),
        headers: _headers,
      ).timeout(_timeout);

      if (res.statusCode == 200) {
        final rawList = jsonDecode(res.body) as List<dynamic>;
        return rawList.map<List<int>>((week) {
          final days = week['days'] as List<dynamic>? ?? [];
          return days.map<int>((d) => (d as num).toInt()).toList();
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // ── DELETE /api/projects/:id ─────────────────────────────────────────────────
  static Future<void> deleteProject(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/projects/$id'),
      headers: _headers,
    ).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception(
          (jsonDecode(res.body) as Map)['error'] ?? 'Failed to delete project');
    }
  }

  // ── PATCH /api/projects/:id ──────────────────────────────────────────────────
  static Future<Project> editProject(String id,
      {String? liveUrl, String? videoUrl}) async {
    final body = <String, String>{};
    if (liveUrl != null)  body['liveUrl']  = liveUrl;
    if (videoUrl != null) body['videoUrl'] = videoUrl;

    final res = await http.patch(
      Uri.parse('$baseUrl/projects/$id'),
      headers: _headers,
      body: jsonEncode(body),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return Project.fromJson(data['project'] as Map<String, dynamic>);
    }
    throw Exception(
        (jsonDecode(res.body) as Map)['error'] ?? 'Failed to edit project');
  }

  // ── POST /api/projects/:id/readme ────────────────────────────────────────────
  static Future<String> generateReadme(String id) async {
    final res = await http.post(
      Uri.parse('$baseUrl/projects/$id/readme'),
      headers: _headers,
    ).timeout(const Duration(seconds: 40));

    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map)['readme'] as String? ?? '';
    }
    throw Exception('Failed to generate README');
  }

  // ── GET /api/projects/public ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getPublicFeed({
    String? stack,
    String? language,
    String sort = 'newest',
    int page = 1,
  }) async {
    final params = <String, String>{'sort': sort, 'page': '$page'};
    if (stack != null && stack.isNotEmpty)       params['stack']    = stack;
    if (language != null && language.isNotEmpty) params['language'] = language;

    final uri = Uri.parse('$baseUrl/projects/public')
        .replace(queryParameters: params);
    final res = await http.get(uri).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return {
        'total': data['total'] as int? ?? 0,
        'projects': (data['projects'] as List<dynamic>)
            .map((e) => Project.fromJson(e as Map<String, dynamic>))
            .toList(),
      };
    }
    throw Exception('Failed to load discovery feed');
  }

  // ── GET /api/auth/profile/:userId ────────────────────────────────────────────
  static Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/profile/$userId'),
    ).timeout(_timeout);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return {
        'user': data['user'],
        'stats': data['stats'],
        'projects': (data['projects'] as List<dynamic>)
            .map((e) => Project.fromJson(e as Map<String, dynamic>))
            .toList(),
      };
    }
    throw Exception('Profile not found');
  }

  // ── GET /api/health ─────────────────────────────────────────────────────────
  static Future<bool> checkHealth() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }
}
