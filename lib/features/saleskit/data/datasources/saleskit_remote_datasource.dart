import 'package:dio/dio.dart';

abstract class SalesKitRemoteDataSource {
  Future<List<Map<String, dynamic>>> getTownships();
  Future<List<Map<String, dynamic>>> getClusters(int townshipId);
  Future<List<Map<String, dynamic>>> getCommercials(int townshipId);
}

class SalesKitRemoteDataSourceImpl implements SalesKitRemoteDataSource {
  final Dio dio;
  SalesKitRemoteDataSourceImpl(this.dio);

  @override
  Future<List<Map<String, dynamic>>> getTownships() async {
    try {
      final response = await dio.get('/property/townships');
      final data = response.data;
      if (data['status'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Gagal mengambil data township');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengambil data township');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getClusters(int townshipId) async {
    try {
      final response = await dio.get('/property/clusters/$townshipId');
      final data = response.data;
      if (data['status'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Gagal mengambil data cluster');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengambil data cluster');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCommercials(int townshipId) async {
    try {
      final response = await dio.get('/property/commercials/$townshipId');
      final data = response.data;
      if (data['status'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Gagal mengambil data commercial');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengambil data commercial');
    }
  }
}
