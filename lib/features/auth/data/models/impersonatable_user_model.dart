/// User yang bisa di-impersonate oleh superadmin (dari GET /auth/impersonate/users).
class ImpersonatableUser {
  final int userId;
  final String fullName;
  final String username;
  final String? email;
  final String? roleName;
  /// Detail "Sales Team - Jabatan" (sales) atau "Role" (non-sales) — sama dgn dropdown Owner web.
  final String? detail;

  ImpersonatableUser({
    required this.userId,
    required this.fullName,
    required this.username,
    this.email,
    this.roleName,
    this.detail,
  });

  factory ImpersonatableUser.fromJson(Map<String, dynamic> json) {
    return ImpersonatableUser(
      userId: json['user_id'] is int
          ? json['user_id'] as int
          : int.tryParse('${json['user_id']}') ?? 0,
      fullName: (json['full_name'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: json['email']?.toString(),
      roleName: json['role_name']?.toString(),
      detail: json['detail']?.toString(),
    );
  }
}
