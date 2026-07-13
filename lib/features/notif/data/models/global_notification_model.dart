class GlobalNotificationEntity {
  final int id;
  final String title;
  final String? description;
  final String? mediaType;
  final String? mediaUrl;
  final String? linkUrl;
  final DateTime createdAt;

  GlobalNotificationEntity({
    required this.id,
    required this.title,
    this.description,
    this.mediaType,
    this.mediaUrl,
    this.linkUrl,
    required this.createdAt,
  });

  static int _toInt(dynamic v) => v is int ? v : (int.tryParse('${v ?? ''}') ?? 0);

  factory GlobalNotificationEntity.fromJson(Map<String, dynamic> j) {
    return GlobalNotificationEntity(
      id: _toInt(j['global_notification_id']),
      title: (j['title'] ?? '').toString(),
      description: j['description']?.toString(),
      mediaType: j['media_type']?.toString(),
      mediaUrl: j['media_url']?.toString(),
      linkUrl: j['link_url']?.toString(),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime(2000),
    );
  }
}
