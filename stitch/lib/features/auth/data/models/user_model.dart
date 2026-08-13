/// Auth data model with JSON serialization.
library;

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String? avatarUrl;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'avatar_url': avatarUrl,
      'created_at': createdAt,
    };
  }
}
