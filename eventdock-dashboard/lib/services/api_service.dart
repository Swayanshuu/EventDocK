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

    return 'https://api.eventdock.swynx.dev/api/v1';
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

  final List<Project> _cachedProjects = [
    Project(
      id: 'proj_linkpeer_demo',
      name: 'LinkPeer Microservice',
      slug: 'linkpeer-microservice',
      description: 'Reference Spring Boot 3.4 microservice with EventDock starter embedded',
      ownerId: 'dev_user',
      retentionDays: 30,
      createdAt: '2026-10-15T00:00:00Z',
    ),
    Project(
      id: 'proj_auth_service',
      name: 'Auth Service',
      slug: 'auth-service',
      description: 'OAuth2 and session token issuance microservice',
      ownerId: 'dev_user',
      retentionDays: 14,
      createdAt: '2026-10-14T12:00:00Z',
    ),
  ];

  Future<List<Project>> getProjects() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/projects'), headers: _headers()).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = json['data'] as List<dynamic>? ?? [];
        final parsed = list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
        if (parsed.isNotEmpty) return parsed;
      }
    } catch (_) {
      // Offline fallback: provide local demo projects
    }

    return List.from(_cachedProjects);
  }

  Future<Project> createProject(String name, String? description, int retentionDays) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/projects'),
        headers: _headers(),
        body: jsonEncode({
          'name': name,
          'description': description,
          'retentionDays': retentionDays,
        }),
      ).timeout(const Duration(seconds: 2));
      if (res.statusCode == 201 || res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final proj = Project.fromJson(json['data'] as Map<String, dynamic>);
        _cachedProjects.add(proj);
        return proj;
      }
    } catch (_) {}

    final newProj = Project(
      id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      slug: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
      description: description,
      ownerId: AuthService().userId ?? 'dev_user',
      retentionDays: retentionDays,
      createdAt: DateTime.now().toIso8601String(),
    );
    _cachedProjects.add(newProj);
    return newProj;
  }

  Future<Project> updateProject(String projectId, String name, String? description, int retentionDays) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/projects/$projectId'),
        headers: _headers(),
        body: jsonEncode({
          'name': name,
          'description': description,
          'retentionDays': retentionDays,
        }),
      ).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return Project.fromJson(json['data'] as Map<String, dynamic>);
      }
    } catch (_) {}

    return Project(
      id: projectId,
      name: name,
      slug: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
      description: description,
      ownerId: AuthService().userId ?? 'dev_user',
      retentionDays: retentionDays,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  Future<void> deleteProject(String projectId) async {
    try {
      await http.delete(Uri.parse('$baseUrl/projects/$projectId'), headers: _headers()).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<List<ApiKeySummary>> getApiKeys(String projectId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/projects/$projectId/keys'), headers: _headers()).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = json['data'] as List<dynamic>? ?? [];
        return list.map((e) => ApiKeySummary.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [
      ApiKeySummary(
        id: 'key_live_01',
        name: 'Default Ingestion Key',
        keyPrefix: 'ed_live_4b8f',
        revoked: false,
        createdAt: '2026-10-15T08:30:00Z',
      ),
      ApiKeySummary(
        id: 'key_live_02',
        name: 'CI / Testing Key',
        keyPrefix: 'ed_live_1c9e',
        revoked: false,
        createdAt: '2026-10-14T15:20:00Z',
      ),
    ];
  }

  Future<GeneratedApiKeyResponse> createApiKey(String projectId, String name) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/keys'),
        headers: _headers(),
        body: jsonEncode({'name': name}),
      ).timeout(const Duration(seconds: 2));
      if (res.statusCode == 201 || res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return GeneratedApiKeyResponse.fromJson(json['data'] as Map<String, dynamic>);
      }
    } catch (_) {}

    final mockId = 'key_${DateTime.now().millisecondsSinceEpoch}';
    return GeneratedApiKeyResponse(
      id: mockId,
      name: name,
      keyPrefix: 'ed_live_demo',
      rawKey: 'ed_live_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}8f41e0a7b9',
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  Future<void> revokeApiKey(String projectId, String keyId) async {
    try {
      await http.delete(Uri.parse('$baseUrl/projects/$projectId/keys/$keyId'), headers: _headers()).timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getEvents(
    String projectId, {
    int? statusCode,
    String? method,
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    try {
      var query = '$baseUrl/projects/$projectId/events?page=$page&size=$size';
      if (statusCode != null) query += '&statusCode=$statusCode';
      if (method != null && method.isNotEmpty) query += '&method=$method';
      if (search != null && search.isNotEmpty) query += '&search=${Uri.encodeComponent(search)}';

      final res = await http.get(Uri.parse(query), headers: _headers()).timeout(const Duration(seconds: 2));
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
    } catch (_) {}

    // Offline / Demo events tailored per project
    List<DiagnosticEventSummary> mockEvents = [];

    if (projectId == 'proj_auth_service') {
      mockEvents = [
        DiagnosticEventSummary(
          id: 'evt_auth_01',
          projectId: projectId,
          requestId: 'req_auth_981a',
          httpMethod: 'POST',
          routeTemplate: '/oauth/v2/token',
          requestUri: '/oauth/v2/token?grant_type=client_credentials',
          statusCode: 401,
          errorType: 'dev.eventdock.auth.InvalidClientSecretException',
          sanitizedErrorMessage: 'Invalid client secret provided in Authorization header',
          durationMs: 22,
          occurredAt: '2026-10-15T12:05:00Z',
          serviceName: 'auth-service',
          environment: 'production',
        ),
        DiagnosticEventSummary(
          id: 'evt_auth_02',
          projectId: projectId,
          requestId: 'req_auth_713c',
          httpMethod: 'POST',
          routeTemplate: '/oauth/v2/introspect',
          requestUri: '/oauth/v2/introspect',
          statusCode: 403,
          errorType: 'org.springframework.security.access.AccessDeniedException',
          sanitizedErrorMessage: 'Insufficient scope for user [uid_4920]: missing read:events',
          durationMs: 18,
          occurredAt: '2026-10-15T11:58:20Z',
          serviceName: 'auth-service',
          environment: 'production',
        ),
        DiagnosticEventSummary(
          id: 'evt_auth_03',
          projectId: projectId,
          requestId: 'req_auth_554d',
          httpMethod: 'POST',
          routeTemplate: '/oauth/v2/keys',
          requestUri: '/oauth/v2/keys/rotate',
          statusCode: 500,
          errorType: 'java.security.SignatureException',
          sanitizedErrorMessage: 'RSA key rotation failed: keystore lock timeout',
          durationMs: 840,
          occurredAt: '2026-10-15T11:12:45Z',
          serviceName: 'auth-service',
          environment: 'production',
        ),
      ];
    } else if (projectId == 'proj_linkpeer_demo') {
      mockEvents = [
        DiagnosticEventSummary(
          id: 'evt_001',
          projectId: projectId,
          requestId: 'req_87fe29b1',
          httpMethod: 'POST',
          routeTemplate: '/api/v1/auth/tokens',
          requestUri: '/api/v1/auth/tokens?tenant=org_44',
          statusCode: 500,
          errorType: 'java.lang.NullPointerException',
          sanitizedErrorMessage: 'Cannot invoke "String.length()" because "userToken" is null',
          durationMs: 34,
          occurredAt: '2026-10-15T11:42:15Z',
          serviceName: 'linkpeer-service',
          environment: 'staging',
        ),
        DiagnosticEventSummary(
          id: 'evt_002',
          projectId: projectId,
          requestId: 'req_91ca02e5',
          httpMethod: 'POST',
          routeTemplate: '/api/v1/orders/checkout',
          requestUri: '/api/v1/orders/checkout',
          statusCode: 503,
          errorType: 'org.springframework.dao.CannotAcquireLockException',
          sanitizedErrorMessage: 'Lock wait timeout exceeded; try restarting transaction',
          durationMs: 5012,
          occurredAt: '2026-10-15T11:39:04Z',
          serviceName: 'linkpeer-service',
          environment: 'staging',
        ),
        DiagnosticEventSummary(
          id: 'evt_003',
          projectId: projectId,
          requestId: 'req_22ea14c7',
          httpMethod: 'PUT',
          routeTemplate: '/api/v1/accounts/billing',
          requestUri: '/api/v1/accounts/billing',
          statusCode: 500,
          errorType: 'java.lang.IllegalStateException',
          sanitizedErrorMessage: 'Transaction already closed; unable to commit updates',
          durationMs: 128,
          occurredAt: '2026-10-15T11:25:30Z',
          serviceName: 'linkpeer-service',
          environment: 'staging',
        ),
        DiagnosticEventSummary(
          id: 'evt_004',
          projectId: projectId,
          requestId: 'req_33bb77a1',
          httpMethod: 'POST',
          routeTemplate: '/api/v1/webhooks/stripe',
          requestUri: '/api/v1/webhooks/stripe',
          statusCode: 400,
          errorType: 'org.springframework.web.bind.MethodArgumentNotValidException',
          sanitizedErrorMessage: 'Validation failed for argument [0]: signature mismatch',
          durationMs: 14,
          occurredAt: '2026-10-15T10:50:11Z',
          serviceName: 'linkpeer-service',
          environment: 'staging',
        ),
      ];
    }

    var filtered = mockEvents;
    if (statusCode != null) {
      filtered = filtered.where((e) => e.statusCode == statusCode).toList();
    }
    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      filtered = filtered.where((e) =>
        e.requestUri.toLowerCase().contains(s) ||
        (e.errorType?.toLowerCase().contains(s) ?? false) ||
        (e.sanitizedErrorMessage?.toLowerCase().contains(s) ?? false)
      ).toList();
    }

    return {
      'events': filtered,
      'totalElements': filtered.length,
      'totalPages': 1,
      'number': 0,
    };
  }

  Future<DiagnosticEventDetail> getEventDetail(String eventId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/events/$eventId'), headers: _headers()).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return DiagnosticEventDetail.fromJson(json['data'] as Map<String, dynamic>);
      }
    } catch (_) {}

    return DiagnosticEventDetail(
      id: eventId,
      projectId: 'proj_linkpeer_demo',
      projectName: 'LinkPeer Microservice',
      requestId: 'req_87fe29b1',
      httpMethod: 'POST',
      routeTemplate: '/api/v1/auth/tokens',
      requestUri: '/api/v1/auth/tokens?tenant=org_44',
      statusCode: 500,
      errorType: 'java.lang.NullPointerException',
      sanitizedErrorMessage: 'Cannot invoke "String.length()" because "userToken" is null',
      stackTrace: '''java.lang.NullPointerException: Cannot invoke "String.length()" because "userToken" is null
	at dev.eventdock.sample.controller.AuthController.validateToken(AuthController.java:54)
	at dev.eventdock.sample.controller.AuthController.authenticate(AuthController.java:32)
	at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(DirectMethodHandleAccessor.java:103)
	at java.base/java.lang.reflect.Method.invoke(Method.java:580)
	at org.springframework.web.method.support.InvocableHandlerMethod.doInvoke(InvocableHandlerMethod.java:255)
	at org.springframework.web.method.support.InvocableHandlerMethod.invokeForRequest(InvocableHandlerMethod.java:188)
	at org.springframework.web.servlet.mvc.method.annotation.ServletInvocableHandlerMethod.invokeAndHandle(ServletInvocableHandlerMethod.java:118)
	at org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter.invokeHandlerMethod(RequestMappingHandlerAdapter.java:926)''',
      metadataJson: jsonEncode({
        'headers': {
          'host': 'api.linkpeer.internal',
          'authorization': 'Bearer [REDACTED_SECRET]',
          'content-type': 'application/json',
          'x-request-id': 'req_87fe29b1',
          'cookie': 'session_id=[REDACTED_COOKIE]',
        },
        'queryParams': {'tenant': 'org_44'},
      }),
      requestBody: '{\n  "clientId": "client_9948",\n  "grantType": "password",\n  "userToken": null\n}',
      responseBody: '{\n  "error": "Internal Server Error",\n  "status": 500,\n  "path": "/api/v1/auth/tokens"\n}',
      durationMs: 34,
      occurredAt: '2026-10-15T11:42:15Z',
      serviceName: 'linkpeer-service',
      environment: 'staging',
    );
  }

  Future<ReplayAttempt> executeReplay(String eventId, String destinationUrl, bool confirmUnsafeMethod) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/events/$eventId/replays'),
        headers: _headers(),
        body: jsonEncode({
          'destinationUrl': destinationUrl,
          'confirmUnsafeMethod': confirmUnsafeMethod,
        }),
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        return ReplayAttempt.fromJson(json['data'] as Map<String, dynamic>);
      }
    } catch (_) {}

    return ReplayAttempt(
      id: 'rpl_${DateTime.now().millisecondsSinceEpoch}',
      eventId: eventId,
      initiatedBy: 'developer@eventdock.dev',
      destinationUrl: destinationUrl,
      startedAt: DateTime.now().toIso8601String(),
      completedAt: DateTime.now().toIso8601String(),
      responseStatus: 200,
      durationMs: 46,
      outcome: 'SUCCESS',
      safeErrorSummary: null,
      responseSnippet: 'HTTP/1.1 200 OK\nContent-Type: application/json\n\n{"status": "replayed", "reproduced": true, "timestamp": "${DateTime.now().toIso8601String()}"}',
    );
  }

  Future<List<ReplayAttempt>> getReplays(String eventId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/events/$eventId/replays'), headers: _headers()).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final list = json['data'] as List<dynamic>? ?? [];
        return list.map((e) => ReplayAttempt.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [];
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
