import 'package:frontend/core/common/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.username,
    super.avatarUrl,
    super.role = 'free',
    super.proExpiresAt,
  });


  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email:
          json['email'] as String? ??
          json['user_metadata']?['email'] as String? ??
          '',
      fullName: json['user_metadata']?['full_name'] as String?,
      username: json['user_metadata']?['username'] as String?,
      avatarUrl: json['user_metadata']?['avatar_url'] as String?,
      role: json['role'] as String? ?? 'free',
      proExpiresAt: json['pro_expires_at'] != null 
          ? DateTime.parse(json['pro_expires_at'] as String).toLocal()
          : null,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? avatarUrl,
    String? role,
    DateTime? proExpiresAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      proExpiresAt: proExpiresAt ?? this.proExpiresAt,
    );
  }
}
