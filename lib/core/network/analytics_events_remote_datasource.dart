import 'package:dio/dio.dart';
import 'package:progress_group/core/network/api_constants.dart';

class AnalyticsEventsRemoteDataSource {
  final Dio dio;
  AnalyticsEventsRemoteDataSource(this.dio);

  Future<List<Map<String, dynamic>>> getAnalyticsEvents() async {
    try {
      final response = await dio.get(ApiConstants.analyticsEventsEndpoint);
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
