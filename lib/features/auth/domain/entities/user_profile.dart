class UserProfileEntity {
  final int userId;
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;
  final bool isActive;
  final String? photo;
  final String permissionScope;

  UserProfileEntity({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.isActive,
    this.photo,
    required this.permissionScope,
  });
}
