class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String roleTitle;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.roleTitle = 'Product Contributor',
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? 'User',
      avatarUrl: json['avatar_url'] as String?,
      roleTitle: json['role_title'] as String? ?? 'Product Contributor',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role_title': roleTitle,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? roleTitle,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      roleTitle: roleTitle ?? this.roleTitle,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
