import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../network/api_constants.dart';

class SalesbookSyncService {
  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static Future<void> syncContact(int contactId) async {
    try {
      final response = await _dio.post(
        ApiConstants.salesbookWebhookUrl,
        data: FormData.fromMap({'contact_id': contactId}),
        options: Options(headers: {'X-App-Token': ApiConstants.salesbookWebhookToken}),
      );
      // debugPrint('[SalesbookSync] contact_id=$contactId → ${response.statusCode} ${response.data}');
    } catch (e) {
      debugPrint('[SalesbookSync] ERROR contact_id=$contactId → $e');
    }
  }
}
