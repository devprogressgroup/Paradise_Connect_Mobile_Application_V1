import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

abstract class SiteplanRemoteDataSource {
  Future<Map<String, dynamic>> getSiteplanSettings();
}

class SiteplanRemoteDataSourceImpl implements SiteplanRemoteDataSource {
  final Dio dio;
  SiteplanRemoteDataSourceImpl(this.dio);

  @override
  Future<Map<String, dynamic>> getSiteplanSettings() async {
    try {
      final response = await dio.get('/property/siteplan-settings');
      debugPrint('SITE PLAN raw response: ${const JsonEncoder.withIndent('  ').convert(response.data)}');
      final data = response.data;
      if (data['status'] == true) {
        return Map<String, dynamic>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Gagal mengambil data siteplan');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengambil data siteplan');
    }
  }
}
