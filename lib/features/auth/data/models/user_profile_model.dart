import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfileEntity {
  UserProfileModel({
    required super.userId,
    required super.fullName,
    required super.username,
    required super.email,
    required super.phoneNumber,
    required super.isActive,
    super.photo,
    required super.permissionScope,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id'],
      fullName: json['full_name'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      isActive: json['is_active'] ?? false,
      photo: json['photo'],
      permissionScope: json['permission_scope'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'is_active': isActive,
      'photo': photo,
      'permission_scope': permissionScope,
    };
  }
}
