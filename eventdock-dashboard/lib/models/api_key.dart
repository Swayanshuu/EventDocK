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
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      keyPrefix: (json['keyPrefix'] ?? '').toString(),
      revoked: json['revoked'] as bool? ?? false,
      createdAt: json['createdAt']?.toString() ?? '',
      revokedAt: json['revokedAt']?.toString(),
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
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      keyPrefix: (json['keyPrefix'] ?? '').toString(),
      rawKey: (json['rawKey'] ?? '').toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
