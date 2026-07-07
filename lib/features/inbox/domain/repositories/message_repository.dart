
import 'package:progress_group/core/network/base_response.dart';
import 'package:progress_group/features/inbox/data/datasources/message_remote_datasource.dart';
import 'package:progress_group/features/inbox/data/models/chat_message_model.dart';

import '../entities/chat_message_entity.dart';

abstract class MessageRepository {
  Future<ChatHistory> getMessages(String sessionId, String jid, {int page = 1});
}



class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;

  MessageRepositoryImpl(this.remoteDataSource);

  @override
  Future<ChatHistory> getMessages(String sessionId, String jid, {int page = 1}) async {
    final result = await remoteDataSource.getMessages(sessionId, jid, page: page);

  
    final response = BaseResponse<Map<String, dynamic>>.fromJson(result, (data) => data);

    if (!response.status) {
      throw Exception(response.message);
    }

    final data = response.data!;
    
    final messages = (data['messages'] as List? ?? [])
        .map((e) => ChatMessageModel.fromJson(e))
        .toList();
        
    final contactInfo = ChatContactInfoModel.fromJson(data['contact_info'] ?? {});

    return ChatHistory(messages: messages, contactInfo: contactInfo);
  }
}