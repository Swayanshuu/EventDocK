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
  });

  factory DiagnosticEventSummary.fromJson(Map<String, dynamic> json) {
    return DiagnosticEventSummary(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      requestId: json['requestId'] as String,
      httpMethod: json['httpMethod'] as String? ?? 'GET',
      routeTemplate: json['routeTemplate'] as String?,
      requestUri: json['requestUri'] as String? ?? '/',
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 500,
      errorType: json['errorType'] as String?,
      sanitizedErrorMessage: json['sanitizedErrorMessage'] as String?,
      durationMs: (json['durationMs'] as num?)?.toInt(),
      occurredAt: json['occurredAt'] as String? ?? '',
      serviceName: json['serviceName'] as String?,
      environment: json['environment'] as String?,
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
  });

  factory DiagnosticEventDetail.fromJson(Map<String, dynamic> json) {
    return DiagnosticEventDetail(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String? ?? 'Project',
      requestId: json['requestId'] as String,
      httpMethod: json['httpMethod'] as String? ?? 'GET',
      routeTemplate: json['routeTemplate'] as String?,
      requestUri: json['requestUri'] as String? ?? '/',
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 500,
      errorType: json['errorType'] as String?,
      sanitizedErrorMessage: json['sanitizedErrorMessage'] as String?,
      stackTrace: json['stackTrace'] as String?,
      durationMs: (json['durationMs'] as num?)?.toInt(),
      occurredAt: json['occurredAt'] as String? ?? '',
      serviceName: json['serviceName'] as String?,
      environment: json['environment'] as String?,
      metadataJson: json['metadataJson'] as String?,
      requestBody: json['requestBody'] as String?,
      responseBody: json['responseBody'] as String?,
    );
  }
}
