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
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      initiatedBy: json['initiatedBy'] as String,
      destinationUrl: json['destinationUrl'] as String,
      startedAt: json['startedAt'] as String? ?? '',
      completedAt: json['completedAt'] as String?,
      responseStatus: (json['responseStatus'] as num?)?.toInt(),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      outcome: json['outcome'] as String? ?? 'UNKNOWN',
      safeErrorSummary: json['safeErrorSummary'] as String?,
      responseSnippet: json['responseSnippet'] as String?,
    );
  }
}
