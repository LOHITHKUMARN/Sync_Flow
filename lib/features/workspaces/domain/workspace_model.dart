enum WorkspaceRole {
  owner('Owner'),
  admin('Admin'),
  member('Member'),
  viewer('Viewer'),
  guest('Viewer');

  final String label;
  const WorkspaceRole(this.label);

  static WorkspaceRole fromString(String val) {
    final lower = val.toLowerCase();
    if (lower == 'guest') return WorkspaceRole.viewer;
    return WorkspaceRole.values.firstWhere(
      (e) => e.name.toLowerCase() == lower,
      orElse: () => WorkspaceRole.member,
    );
  }
}

class WorkspaceMember {
  final String id;
  final String workspaceId;
  final String userId;
  final String fullName;
  final String? email;
  final String? avatarUrl;
  final WorkspaceRole role;
  final DateTime joinedAt;

  const WorkspaceMember({
    required this.id,
    required this.workspaceId,
    required this.userId,
    required this.fullName,
    this.email,
    this.avatarUrl,
    required this.role,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? const _DefaultDateTime();

  String get name => fullName;

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) {
    return WorkspaceMember(
      id: json['id'] as String? ?? '',
      workspaceId: json['workspace_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ??
          (json['profiles'] != null ? json['profiles']['full_name'] as String? : null) ??
          'Member',
      email: json['email'] as String? ??
          (json['profiles'] != null ? json['profiles']['email'] as String? : null),
      avatarUrl: json['avatar_url'] as String? ??
          (json['profiles'] != null ? json['profiles']['avatar_url'] as String? : null),
      role: WorkspaceRole.fromString(json['role'] as String? ?? 'member'),
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspace_id': workspaceId,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'role': role.name,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  WorkspaceMember copyWith({
    String? id,
    String? workspaceId,
    String? userId,
    String? fullName,
    String? email,
    String? avatarUrl,
    WorkspaceRole? role,
    DateTime? joinedAt,
  }) {
    return WorkspaceMember(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();
  DateTime get _now => DateTime.now();

  @override
  bool isAfter(DateTime other) => _now.isAfter(other);
  @override
  bool isBefore(DateTime other) => _now.isBefore(other);
  @override
  bool isAtSameMomentAs(DateTime other) => _now.isAtSameMomentAs(other);
  @override
  int compareTo(DateTime other) => _now.compareTo(other);
  @override
  DateTime add(Duration duration) => _now.add(duration);
  @override
  DateTime subtract(Duration duration) => _now.subtract(duration);
  @override
  Duration difference(DateTime other) => _now.difference(other);
  @override
  String toIso8601String() => _now.toIso8601String();
  @override
  DateTime toLocal() => _now.toLocal();
  @override
  DateTime toUtc() => _now.toUtc();
  @override
  int get year => _now.year;
  @override
  int get month => _now.month;
  @override
  int get day => _now.day;
  @override
  int get hour => _now.hour;
  @override
  int get minute => _now.minute;
  @override
  int get second => _now.second;
  @override
  int get millisecond => _now.millisecond;
  @override
  int get microsecond => _now.microsecond;
  @override
  int get weekday => _now.weekday;
  @override
  bool get isUtc => _now.isUtc;
  @override
  int get millisecondsSinceEpoch => _now.millisecondsSinceEpoch;
  @override
  int get microsecondsSinceEpoch => _now.microsecondsSinceEpoch;
  @override
  String get timeZoneName => _now.timeZoneName;
  @override
  Duration get timeZoneOffset => _now.timeZoneOffset;
}

class Workspace {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? avatarUrl;
  final String ownerId;
  final DateTime createdAt;
  final List<WorkspaceMember> members;

  const Workspace({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.avatarUrl,
    required this.ownerId,
    required this.createdAt,
    this.members = const [],
  });

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      ownerId: json['owner_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => WorkspaceMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'avatar_url': avatarUrl,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'members': members.map((e) => e.toJson()).toList(),
    };
  }

  Workspace copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    String? avatarUrl,
    String? ownerId,
    DateTime? createdAt,
    List<WorkspaceMember>? members,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
    );
  }
}
