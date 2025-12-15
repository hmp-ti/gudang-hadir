class User {
  final String id;
  final String name;
  final String username;
  final String role; // 'admin' or 'karyawan'
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      role: json['role'],
      isActive: (json['is_active'] as int) == 1,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'role': role,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
