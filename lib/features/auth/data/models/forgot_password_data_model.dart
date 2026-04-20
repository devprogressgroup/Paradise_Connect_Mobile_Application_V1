class ForgotPasswordDataModel {
  final int userId;
  final String maskedPhone;

  ForgotPasswordDataModel({
    required this.userId,
    required this.maskedPhone,
  });

  factory ForgotPasswordDataModel.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordDataModel(
      userId: json['user_id'],
      maskedPhone: json['masked_phone'],
    );
  }


  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'masked_phone': maskedPhone};
  }
}