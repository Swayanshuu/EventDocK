class DiagnosticEventSummary {
  final String id;
  final String projectId;
  final String requestId;
  final String httpMethod;
  final String? routeTemplate;
  final String requestUri;
  final int statusCode;
  final String? errorType;
  final String? sanitizedErrorMessage;
  final int? durationMs;
  final String occurredAt;
  final String? serviceName;
  final String? environment;
  final bool resolved;

  DiagnosticEventSummary({
    required this.id,
    required this.projectId,
    required this.requestId,
    required this.httpMethod,
    this.routeTemplate,
    required this.requestUri,
    required this.statusCode,
    this.errorType,
    this.sanitizedErrorMessage,
    this.durationMs,
    required this.occurredAt,
    this.serviceName,
    this.environment,
    this.resolved = false,
  });

  factory DiagnosticEventSummary.fromJson(Map<String, dynamic> json) {
    return DiagnosticEventSummary(
      id: (json['id'] ?? '').toString(),
      projectId: (json['projectId'] ?? '').toString(),
      requestId: (json['requestId'] ?? '').toString(),
      httpMethod: (json['httpMethod'] ?? 'GET').toString(),
      routeTemplate: json['routeTemplate']?.toString(),
      requestUri: (json['requestUri'] ?? '/').toString(),
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 500,
      errorType: json['errorType']?.toString(),
      sanitizedErrorMessage: json['sanitizedErrorMessage']?.toString(),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      occurredAt: json['occurredAt']?.toString() ?? '',
      serviceName: json['serviceName']?.toString(),
      environment: json['environment']?.toString(),
      resolved: json['resolved'] == true,
    );
  }
}

class DiagnosticEventDetail {
  final String id;
  final String projectId;
  final String projectName;
  final String requestId;
  final String httpMethod;
  final String? routeTemplate;
  final String requestUri;
  final int statusCode;
  final String? errorType;
  final String? sanitizedErrorMessage;
  final String? stackTrace;
  final int? durationMs;
  final String occurredAt;
  final String? serviceName;
  final String? environment;
  final String? metadataJson;
  final String? requestBody;
  final String? responseBody;
  final bool resolved;

  DiagnosticEventDetail({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.requestId,
    required this.httpMethod,
    this.routeTemplate,
    required this.requestUri,
    required this.statusCode,
    this.errorType,
    this.sanitizedErrorMessage,
    this.stackTrace,
    this.durationMs,
    required this.occurredAt,
    this.serviceName,
    this.environment,
    this.metadataJson,
    this.requestBody,
    this.responseBody,
    this.resolved = false,
  });

  factory DiagnosticEventDetail.fromJson(Map<String, dynamic> json) {
    return DiagnosticEventDetail(
      id: (json['id'] ?? '').toString(),
      projectId: (json['projectId'] ?? '').toString(),
      projectName: json['projectName']?.toString() ?? 'Project',
      requestId: (json['requestId'] ?? '').toString(),
      httpMethod: (json['httpMethod'] ?? 'GET').toString(),
      routeTemplate: json['routeTemplate']?.toString(),
      requestUri: (json['requestUri'] ?? '/').toString(),
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 500,
      errorType: json['errorType']?.toString(),
      sanitizedErrorMessage: json['sanitizedErrorMessage']?.toString(),
      stackTrace: json['stackTrace']?.toString(),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      occurredAt: json['occurredAt']?.toString() ?? '',
      serviceName: json['serviceName']?.toString(),
      environment: json['environment']?.toString(),
      metadataJson: json['metadataJson']?.toString(),
      requestBody: json['requestBody']?.toString(),
      responseBody: json['responseBody']?.toString(),
      resolved: json['resolved'] == true,
    );
  }
}
