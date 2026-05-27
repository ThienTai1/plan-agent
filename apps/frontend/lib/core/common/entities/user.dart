class User {
  final String id;
  final String email;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final String role;
  final DateTime? proExpiresAt;

  User({
    required this.id, 
    required this.email, 
    this.fullName,
    this.username,
    this.avatarUrl,
    this.role = 'free',
    this.proExpiresAt,
  });

  bool get isPro {
    if (role != 'pro') return false;
    // Special case for our demo/manual pro users if no expiry set
    if (role == 'pro' && proExpiresAt == null) return true;
    return proExpiresAt!.isAfter(DateTime.now());
  }
}
