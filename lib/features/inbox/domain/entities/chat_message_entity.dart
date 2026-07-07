

class ChatMessage {
  final String id;
  final bool isFromMe;
  final String body;
  final String messageType;
  final String formattedTime;
  final int timestamp;
  final String? senderName;
  final String? mediaUrl;
  final String? caption;

  ChatMessage({
    required this.id,
    required this.isFromMe,
    required this.body,
    required this.messageType,
    required this.formattedTime,
    required this.timestamp,
    this.senderName,
    this.mediaUrl,
    this.caption,
  });
}

class ChatContactInfo {
  final String contactName;
  final String jid;
  final String ownerName;
  final String? photoProfile;

  ChatContactInfo({
    required this.contactName,
    required this.jid,
    required this.ownerName,
    this.photoProfile,
  });
}

class ChatHistory {
  final List<ChatMessage> messages;
  final ChatContactInfo contactInfo;

  ChatHistory({
    required this.messages,
    required this.contactInfo,
  });
}