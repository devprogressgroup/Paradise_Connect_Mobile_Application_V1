class DropdownItemModel {
  final int id;
  final String name;
  final String subtitle;
  final String photo;
  final String count;
  final String time;

  DropdownItemModel({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.photo,
    required this.count,
    required this.time,
  });
}

class InboxContactModel {
  final int id;
  final String name;
  final String? photo;
  final String jid;
  final bool isGroup;
  final String initials;

  InboxContactModel({
    required this.id,
    required this.name,
    required this.photo,
    required this.jid,
    required this.isGroup,
    required this.initials,
  });

  factory InboxContactModel.fromJson(Map<String, dynamic> json) {
    return InboxContactModel(
      id: json["whatsapp_contact_id"],
      name: json["contact_name"] ?? "-",
      photo: json["photo_profile"],
      jid: json["jid"],
      isGroup: json["isGroup"] ?? false,
      initials: json["initials"] ?? "",
    );
  }
}