class Organization {
  final String id;
  final String name;
  final String slug;
  final String type; // 'individual' or 'organization'
  final String plan; // 'Free Developer', 'Team Pro', 'Enterprise'

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.type = 'individual',
    this.plan = 'Free Developer',
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String? ?? 'org_personal',
      name: json['name'] as String? ?? 'Personal Workspace',
      slug: json['slug'] as String? ?? 'personal',
      type: json['type'] as String? ?? 'individual',
      plan: json['plan'] as String? ?? 'Free Developer',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'type': type,
      'plan': plan,
    };
  }
}
