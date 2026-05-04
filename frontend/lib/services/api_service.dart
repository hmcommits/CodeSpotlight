import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project_model.dart';

class ApiService {
  // TODO: Replace with your deployed backend URL before Firebase deploy
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static const Duration _timeout = Duration(seconds: 20);

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ── GET /api/projects ───────────────────────────────────────────────────────
  static Future<List<Project>> getProjects({
    String? stack,
    String? language,
    String? search,
  }) async {
    final params = <String, String>{};
    if (stack != null && stack.isNotEmpty) params['stack'] = stack;
    if (language != null && language.isNotEmpty) params['language'] = language;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$baseUrl/projects').replace(queryParameters: params);

    final response = await http
        .get(uri, headers: _headers)
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['projects'] as List<dynamic>;
      return list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to load projects');
    }
  }

  // ── POST /api/projects ──────────────────────────────────────────────────────
  static Future<Project> submitProject(
    String githubUrl, {
    String liveUrl = '',
    String videoUrl = '',
  }) async {
    final uri = Uri.parse('$baseUrl/projects');
    final response = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({
            'githubUrl': githubUrl,
            'liveUrl': liveUrl,
            'videoUrl': videoUrl,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 200 || response.statusCode == 202) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Project.fromJson(data['project'] as Map<String, dynamic>);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to submit project');
    }
  }

  // ── GET /api/projects/:id ───────────────────────────────────────────────────
  static Future<Project> getProjectById(String id) async {
    final uri = Uri.parse('$baseUrl/projects/$id');
    final response = await http
        .get(uri, headers: _headers)
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Project.fromJson(data['project'] as Map<String, dynamic>);
    } else {
      throw Exception('Project not found');
    }
  }

  // ── POST /api/projects/:id/heartbeat ────────────────────────────────────────
  static Future<String> checkHeartbeat(String id, String liveUrl) async {
    final uri = Uri.parse('$baseUrl/projects/$id/heartbeat');
    final response = await http
        .post(
          uri,
          headers: _headers,
          body: jsonEncode({'liveUrl': liveUrl}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['status'] as String? ?? 'unknown';
    }
    return 'unknown';
  }

  // ── GET /api/health ─────────────────────────────────────────────────────────
  static Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── GET /api/projects/:id/ai-status ─────────────────────────────────────────
  // Poll this every N seconds while aiStatus == 'pending'
  static Future<Map<String, dynamic>> pollAiStatus(String id) async {
    final uri = Uri.parse('$baseUrl/projects/$id/ai-status');
    final response = await http.get(uri, headers: _headers).timeout(_timeout);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to poll AI status');
  }

  // ── POST /api/projects/:id/reanalyze ────────────────────────────────────────
  static Future<void> reanalyze(String id) async {
    final uri = Uri.parse('$baseUrl/projects/$id/reanalyze');
    await http.post(uri, headers: _headers).timeout(_timeout);
  }
}
