import 'package:dio/dio.dart';
import 'package:progress_group/features/app-menu/data/models/app_menu_model.dart';

abstract class AppMenuRemoteDataSource {
  /// GET /api/app-menu
  Future<AppMenuModel> getAppMenu();
}

class AppMenuRemoteDataSourceImpl implements AppMenuRemoteDataSource {
  final Dio dio;

  AppMenuRemoteDataSourceImpl(this.dio);

  @override
  Future<AppMenuModel> getAppMenu() async {
    final response = await dio.get('/app-menu');
    final body = response.data;
    if (body is Map && body['status'] == true && body['data'] is Map) {
      return AppMenuModel.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }
    final message = body is Map ? body['message']?.toString() : null;
    throw Exception(
      (message == null || message.isEmpty) ? 'Gagal memuat menu.' : message,
    );
  }
}
