class ApiKeySummary {
  final String id;
  final String name;
  final String keyPrefix;
  final bool revoked;
  final String createdAt;
  final String? revokedAt;

  ApiKeySummary({
    required this.id,
    required this.name,
    required this.keyPrefix,
    required this.revoked,
    required this.createdAt,
    this.revokedAt,
  });

  factory ApiKeySummary.fromJson(Map<String, dynamic> json) {
    return ApiKeySummary(
      id: json['id'] as String,
      name: json['name'] as String,
      keyPrefix: json['keyPrefix'] as String,
      revoked: json['revoked'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      revokedAt: json['revokedAt'] as String?,
    );
  }
}

class GeneratedApiKeyResponse {
  final String id;
  final String name;
  final String keyPrefix;
  final String rawKey;
  final String createdAt;

  GeneratedApiKeyResponse({
    required this.id,
    required this.name,
    required this.keyPrefix,
    required this.rawKey,
    required this.createdAt,
  });

  factory GeneratedApiKeyResponse.fromJson(Map<String, dynamic> json) {
    return GeneratedApiKeyResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      keyPrefix: json['keyPrefix'] as String,
      rawKey: json['rawKey'] as String,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
