class Project {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String ownerId;
  final int retentionDays;
  final String createdAt;

  Project({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.ownerId,
    required this.retentionDays,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      description: json['description']?.toString(),
      ownerId: (json['ownerId'] ?? '').toString(),
      retentionDays: (json['retentionDays'] as num?)?.toInt() ?? 30,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
