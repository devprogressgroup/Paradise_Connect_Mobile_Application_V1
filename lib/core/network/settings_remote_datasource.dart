import 'package:dio/dio.dart';

class SettingsRemoteDataSource {
  final Dio dio;
  SettingsRemoteDataSource(this.dio);

  Future<List<Map<String, dynamic>>> getSettings() async {
    try {
      final response = await dio.get('/settings');
      final data = response.data;
      if (data['status'] == true) {
        return List<Map<String, dynamic>>.from(data['data'] as List);
      }
      return [];
    } on DioException {
      return [];
    }
  }
}
