class LoginDataModel {
  final int userId;
  final String accessToken;

  LoginDataModel({
    required this.userId,
    required this.accessToken,
  });

  factory LoginDataModel.fromJson(Map<String, dynamic> json) {
    return LoginDataModel(
      userId: json['user_id'] ?? 0,
      accessToken: json['access_token'] ?? '',
    );
  }
}