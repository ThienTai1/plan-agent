class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String? fullName;

  RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    this.fullName,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'password': password,
      if (fullName != null) 'full_name': fullName,
    };
  }
}

class TokenResponse {
  final String accessToken;
  final DateTime? expiresAt;

  TokenResponse({
    required this.accessToken,
    this.expiresAt,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }
}

class User {
  final String id;
  final String email;
  final String? fullName;

  User({
    required this.id,
    required this.email,
    this.fullName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
    );
  }
}

