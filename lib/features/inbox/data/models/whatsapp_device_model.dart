class WhatsappDeviceModel {
  final int whatsappNumberId;
  final int userId;
  final String sessionCode;
  final String whatsappNumber;
  final String status;
  final bool isActive;
  final String? lastConnected;
  final String? lastDisconnected;
  final AppUser? user;

  WhatsappDeviceModel({
    required this.whatsappNumberId,
    required this.userId,
    required this.sessionCode,
    required this.whatsappNumber,
    required this.status,
    required this.isActive,
    this.lastConnected,
    this.lastDisconnected,
    this.user,
  });

  factory WhatsappDeviceModel.fromJson(Map<String, dynamic> json) {
    return WhatsappDeviceModel(
      whatsappNumberId: json['whatsapp_number_id'],
      userId: json['user_id'],
      sessionCode: json['session_code'],
      whatsappNumber: json['whatsapp_number'],
      status: json['status'],
      isActive: json['is_active'],
      lastConnected: json['last_connected'],
      lastDisconnected: json['last_disconnected'],
      user: json['m_app_user'] != null ? AppUser.fromJson(json['m_app_user']) : null,
    );
  }
}

class AppUser {
  final int userId;
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;

  AppUser({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      userId: json['user_id'],
      fullName: json['full_name'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phone_number'],
    );
  }
}
