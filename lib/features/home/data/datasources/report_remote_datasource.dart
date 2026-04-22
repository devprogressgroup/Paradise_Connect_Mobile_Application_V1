import 'package:dio/dio.dart';

abstract class ReportRemoteDataSource {
  Future<Map<String, dynamic>> getVolumeReport(String start, String end, String group);
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final Dio dio;
  ReportRemoteDataSourceImpl(this.dio);

  @override
  Future<Map<String, dynamic>> getVolumeReport(String start, String end, String group) async {
    try {
      final response = await dio.get(
        '/whatsapp/report/volume',
        queryParameters: {
          'start_date': start,
          'end_date': end,
          'group_by': group,
        },
      );
      return response.data; // Mengasumsikan Dio Client sudah menangani jsonDecode
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Gagal mengambil data report");
    }
  }
}