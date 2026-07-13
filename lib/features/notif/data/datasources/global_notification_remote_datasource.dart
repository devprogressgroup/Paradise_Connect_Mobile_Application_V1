import 'package:dio/dio.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/notif/data/models/global_notification_model.dart';

abstract class GlobalNotificationRemoteDataSource {
  Future<List<GlobalNotificationEntity>> getNotifications({int page, int perPage});
}

class GlobalNotificationRemoteDataSourceImpl implements GlobalNotificationRemoteDataSource {
  final Dio dio;
  GlobalNotificationRemoteDataSourceImpl(this.dio);

  @override
  Future<List<GlobalNotificationEntity>> getNotifications({int page = 1, int perPage = 20}) async {
    try {
      final response = await dio.get('/notifications', queryParameters: {
        'page': page,
        'per_page': perPage,
      });

      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        final d = Map<String, dynamic>.from(body['data'] as Map);
        final list = (d['data'] as List? ?? []);
        return list.map((e) => GlobalNotificationEntity.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat notifikasi') : 'Gagal memuat notifikasi');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat notifikasi'));
    }
  }
}
