import 'dart:convert';
import 'package:dio/dio.dart';

abstract class InboxContactRemoteDataSource {
  Future<Map<String, dynamic>> getInboxContacts({
    String? search,
    int? cPage,
    int? gPage,
  });
}

class InboxContactRemoteDataSourceImpl implements InboxContactRemoteDataSource {
  final Dio dio;

  InboxContactRemoteDataSourceImpl(this.dio);

  @override
  Future<Map<String, dynamic>> getInboxContacts({String? search, int? cPage, int? gPage}) async {
    try {
      final response = await dio.get(
        '/whatsapp/contacts',
        queryParameters: {
          'search': search ?? '',
          'c_page': cPage ?? 1,
          'g_page': gPage ?? 1,
        },
      );

      if (response.data is String) {
        return jsonDecode(response.data) as Map<String, dynamic>;
      } else if (response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        throw Exception("Format response tidak didukung");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data is String 
            ? jsonDecode(e.response!.data) 
            : e.response!.data;
      } else {
        throw Exception("Tidak dapat terhubung ke server");
      }
    }
  }
}