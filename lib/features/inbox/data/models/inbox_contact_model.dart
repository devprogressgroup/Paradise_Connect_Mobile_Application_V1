import '../../domain/entities/inbox_contact_entity.dart';

class InboxContactModel extends InboxContact {
  InboxContactModel({
    required super.id,
    required super.name,
    super.photo,
    required super.jid,
    required super.isGroup,
    required super.initials,
    super.lastConversationDate,
    super.ownerName,
  });

  factory InboxContactModel.fromJson(Map<String, dynamic> json) {
    return InboxContactModel(
      id: json["whatsapp_contact_id"],
      name: json["contact_name"] ?? "-",
      photo: json["photo_profile"],
      jid: json["jid"] ?? "",
      isGroup: json["isGroup"] ?? false,
      initials: json["initials"] ?? "",
      lastConversationDate: json["last_conversation_date"],
      ownerName: json["owner_name"],
    );
  }

  static List<InboxContactModel> fromJsonList(List<dynamic> list) {
    return list.map((item) => InboxContactModel.fromJson(item)).toList();
  }
}