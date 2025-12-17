class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' or 'karyawan'
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['\$id'] ?? json['id'], // Appwrite uses $id
      name: json['name'],
      email: json['email'],
      role: json['role'] ?? 'karyawan',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: DateTime.tryParse(json['\$createdAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
