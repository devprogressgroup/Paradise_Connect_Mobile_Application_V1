class InboxContact {
  final int id;
  final String name;
  final String? photo;
  final String jid;
  final bool isGroup;
  final String initials;
  final String? lastConversationDate;
  final String? ownerName;

  InboxContact({
    required this.id,
    required this.name,
    this.photo,
    required this.jid,
    required this.isGroup,
    required this.initials,
    this.lastConversationDate,
    this.ownerName,
  });
}