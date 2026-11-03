class WorkspaceMember {
  final String id;
  final String name;
  final String email;
  final String role; // 'Owner', 'Admin', 'Member'
  final String status; // 'Active', 'Invited', 'Pending'
  final String joinedAt;
  final String? avatarUrl;

  const WorkspaceMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.status = 'Active',
    required this.joinedAt,
    this.avatarUrl,
  });

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) {
    return WorkspaceMember(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'Member',
      status: json['status'] as String? ?? 'Active',
      joinedAt: json['joinedAt'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'joinedAt': joinedAt,
      'avatarUrl': avatarUrl,
    };
  }

  WorkspaceMember copyWith({
    String? name,
    String? email,
    String? role,
    String? status,
  }) {
    return WorkspaceMember(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt,
      avatarUrl: avatarUrl,
    );
  }
}
