import 'package:progress_group/features/inbox/domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessage {
  ChatMessageModel({
    required super.id,
    required super.isFromMe,
    required super.body,
    required super.messageType,
    required super.formattedTime,
    required super.timestamp,
    super.senderName,
    super.mediaUrl,
    super.caption, 
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      isFromMe: json['is_from_me'] ?? false,
      body: json['body'] ?? '',
      messageType: json['message_type'] ?? 'text',
      formattedTime: json['formatted_time'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      senderName: json['sender']?['name'],
      mediaUrl: json['media_url'], 
      caption: json['caption'], 
    );
  }
}


class ChatContactInfoModel extends ChatContactInfo {
  ChatContactInfoModel({
    required super.contactName,
    required super.jid,
    required super.ownerName,
    super.photoProfile,
  });

  factory ChatContactInfoModel.fromJson(Map<String, dynamic> json) {
    return ChatContactInfoModel(
      contactName: json['contact_name'] ?? 'Unknown',
      jid: json['jid'] ?? '',
      ownerName: json['owner_name'] ?? '',
      photoProfile: json['photo_profile'],
    );
  }
}