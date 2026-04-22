class WhatsappDevice {
  final int id;
  final String whatsappNumber;
  final String status;
  final bool isActive;
  final String? fullName;
  final String sessionCode;

  WhatsappDevice({
    required this.id,
    required this.whatsappNumber,
    required this.status,
    required this.isActive,
    this.fullName,
    required this.sessionCode,
  });
}
