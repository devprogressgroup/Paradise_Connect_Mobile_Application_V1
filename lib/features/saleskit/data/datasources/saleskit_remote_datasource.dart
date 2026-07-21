import 'package:dio/dio.dart';

abstract class SalesKitRemoteDataSource {
  Future<List<Map<String, dynamic>>> getTownships();
  Future<List<Map<String, dynamic>>> getTownshipsSalesKit();
  Future<List<Map<String, dynamic>>> getClusters(int townshipId);
  Future<List<Map<String, dynamic>>> getCommercials(int townshipId);
  Future<Map<String, dynamic>> getClusterMedia({
    required int clusterId,
    required String ownerSegment,
    int? mediaGroupId,
    String? search,
    String sortBy,
    String sortDir,
    int page,
    int perPage,
  });
  Future<void> shareCaption(int captionId);
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
  Future<List<Map<String, dynamic>>> getTownshipsSalesKit() async {
    try {
      final response = await dio.get('/property/townships/saleskit');
      final data = response.data;
      if (data['status'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Gagal mengambil data township saleskit');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengambil data township saleskit');
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

  @override
  Future<Map<String, dynamic>> getClusterMedia({
    required int clusterId,
    required String ownerSegment,
    int? mediaGroupId,
    String? search,
    String sortBy = 'name',
    String sortDir = 'asc',
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      final response = await dio.get(
        '/property/$ownerSegment/$clusterId/media',
        queryParameters: {
          if (mediaGroupId != null) 'media_group_id': mediaGroupId,
          if (search != null && search.isNotEmpty) 'search': search,
          'sort_by': sortBy,
          'sort_dir': sortDir,
          'per_page': perPage,
          'page': page,
        },
      );
      final data = response.data;
      if (data['status'] == true) {
        return Map<String, dynamic>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Gagal mengambil data media');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengambil data media');
    }
  }

  @override
  Future<void> shareCaption(int captionId) async {
    try {
      await dio.post(
        '/property/captions/share',
        queryParameters: {'caption_id': captionId},
      );
    } on DioException catch (_) {
      // Share tracking is best-effort; failures here shouldn't block the user's share action.
    }
  }
}
