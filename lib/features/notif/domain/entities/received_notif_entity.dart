import 'dart:convert';

class ReceivedNotifEntity {
  final String id;
  final String title;
  final String body;
  final String? type;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  const ReceivedNotifEntity({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    required this.data,
    required this.receivedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'data': jsonEncode(data),
    'receivedAt': receivedAt.toIso8601String(),
  };

  factory ReceivedNotifEntity.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> dataMap = {};
    try {
      final raw = json['data'];
      if (raw is String) {
        dataMap = (jsonDecode(raw) as Map?)?.cast<String, dynamic>() ?? {};
      } else if (raw is Map) {
        dataMap = raw.cast<String, dynamic>();
      }
    } catch (_) {}
    return ReceivedNotifEntity(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String?,
      data: dataMap,
      receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
