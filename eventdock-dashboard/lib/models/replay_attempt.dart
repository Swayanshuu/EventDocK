class ReplayAttempt {
  final String id;
  final String eventId;
  final String initiatedBy;
  final String destinationUrl;
  final String startedAt;
  final String? completedAt;
  final int? responseStatus;
  final int? durationMs;
  final String outcome;
  final String? safeErrorSummary;
  final String? responseSnippet;

  ReplayAttempt({
    required this.id,
    required this.eventId,
    required this.initiatedBy,
    required this.destinationUrl,
    required this.startedAt,
    this.completedAt,
    this.responseStatus,
    this.durationMs,
    required this.outcome,
    this.safeErrorSummary,
    this.responseSnippet,
  });

  factory ReplayAttempt.fromJson(Map<String, dynamic> json) {
    return ReplayAttempt(
      id: (json['id'] ?? '').toString(),
      eventId: (json['eventId'] ?? '').toString(),
      initiatedBy: (json['initiatedBy'] ?? '').toString(),
      destinationUrl: (json['destinationUrl'] ?? '').toString(),
      startedAt: json['startedAt']?.toString() ?? '',
      completedAt: json['completedAt']?.toString(),
      responseStatus: (json['responseStatus'] as num?)?.toInt(),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      outcome: json['outcome']?.toString() ?? 'UNKNOWN',
      safeErrorSummary: json['safeErrorSummary']?.toString(),
      responseSnippet: json['responseSnippet']?.toString(),
    );
  }
}
