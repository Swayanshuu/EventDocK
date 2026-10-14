import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/project.dart';
import '../models/api_key.dart';
import '../models/diagnostic_event.dart';
import '../models/replay_attempt.dart';
import 'auth_service.dart';
import 'waitlist_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl {
    const customApi = String.fromEnvironment('EVENTDOCK_API_URL');
    if (customApi.isNotEmpty) return customApi;

    // When hosted on eventdock.swynx.dev, automatically use production API endpoint
    if (Uri.base.host == 'eventdock.swynx.dev') {
      return 'https://api.eventdock.swynx.dev/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  Map<String, String> _headers() {
    final token = AuthService().token;
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<Project>> getProjects() async {
    final res = await http.get(Uri.parse('$baseUrl/projects'), headers: _headers());
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final list = json['data'] as List<dynamic>? ?? [];
      return list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load projects: ${res.statusCode} ${res.body}');
  }

  Future<Project> createProject(String name, String? description, int retentionDays) async {
    final res = await http.post(
      Uri.parse('$baseUrl/projects'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'description': description,
        'retentionDays': retentionDays,
      }),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return Project.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to create project: ${res.statusCode} ${res.body}');
  }

  Future<Project> updateProject(String projectId, String name, String? description, int retentionDays) async {
    final res = await http.put(
      Uri.parse('$baseUrl/projects/$projectId'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'description': description,
        'retentionDays': retentionDays,
      }),
    );
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return Project.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to update project: ${res.statusCode} ${res.body}');
  }

  Future<void> deleteProject(String projectId) async {
    final res = await http.delete(Uri.parse('$baseUrl/projects/$projectId'), headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to delete project: ${res.statusCode} ${res.body}');
    }
  }

  Future<List<ApiKeySummary>> getApiKeys(String projectId) async {
    final res = await http.get(Uri.parse('$baseUrl/projects/$projectId/keys'), headers: _headers());
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final list = json['data'] as List<dynamic>? ?? [];
      return list.map((e) => ApiKeySummary.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load API keys: ${res.statusCode} ${res.body}');
  }

  Future<GeneratedApiKeyResponse> createApiKey(String projectId, String name) async {
    final res = await http.post(
      Uri.parse('$baseUrl/projects/$projectId/keys'),
      headers: _headers(),
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return GeneratedApiKeyResponse.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to generate API key: ${res.statusCode} ${res.body}');
  }

  Future<void> revokeApiKey(String projectId, String keyId) async {
    final res = await http.delete(Uri.parse('$baseUrl/projects/$projectId/keys/$keyId'), headers: _headers());
    if (res.statusCode != 200) {
      throw Exception('Failed to revoke API key: ${res.statusCode} ${res.body}');
    }
  }

  Future<Map<String, dynamic>> getEvents(
    String projectId, {
    int? statusCode,
    String? method,
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    var query = '$baseUrl/projects/$projectId/events?page=$page&size=$size';
    if (statusCode != null) query += '&statusCode=$statusCode';
    if (method != null && method.isNotEmpty) query += '&method=$method';
    if (search != null && search.isNotEmpty) query += '&search=${Uri.encodeComponent(search)}';

    final res = await http.get(Uri.parse(query), headers: _headers());
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final data = json['data'] as Map<String, dynamic>;
      final content = (data['content'] as List<dynamic>? ?? [])
          .map((e) => DiagnosticEventSummary.fromJson(e as Map<String, dynamic>))
          .toList();

      return {
        'events': content,
        'totalElements': data['totalElements'] as int? ?? 0,
        'totalPages': data['totalPages'] as int? ?? 1,
        'number': data['number'] as int? ?? 0,
      };
    }
    throw Exception('Failed to load events: ${res.statusCode} ${res.body}');
  }

  Future<DiagnosticEventDetail> getEventDetail(String eventId) async {
    final res = await http.get(Uri.parse('$baseUrl/events/$eventId'), headers: _headers());
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return DiagnosticEventDetail.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw Exception('Failed to load event detail: ${res.statusCode} ${res.body}');
  }

  Future<ReplayAttempt> executeReplay(String eventId, String destinationUrl, bool confirmUnsafeMethod) async {
    final res = await http.post(
      Uri.parse('$baseUrl/events/$eventId/replays'),
      headers: _headers(),
      body: jsonEncode({
        'destinationUrl': destinationUrl,
        'confirmUnsafeMethod': confirmUnsafeMethod,
      }),
    );
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return ReplayAttempt.fromJson(json['data'] as Map<String, dynamic>);
    }
    throw Exception('Replay execution failed: ${res.statusCode} ${res.body}');
  }

  Future<List<ReplayAttempt>> getReplays(String eventId) async {
    final res = await http.get(Uri.parse('$baseUrl/events/$eventId/replays'), headers: _headers());
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      final list = json['data'] as List<dynamic>? ?? [];
      return list.map((e) => ReplayAttempt.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load replays: ${res.statusCode} ${res.body}');
  }

  http.Client? _client;
  set client(http.Client? c) => _client = c;
  http.Client get client => _client ??= http.Client();

  /// Submit an email to the waitlist (delegated directly to WaitlistService)
  Future<Map<String, dynamic>> submitWaitlist({
    required String email,
    String? name,
    String? company,
  }) async {
    return WaitlistService().submitWaitlist(
      email: email,
      name: name,
      company: company,
    );
  }
}

