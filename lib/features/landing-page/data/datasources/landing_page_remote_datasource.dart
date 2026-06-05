import 'package:dio/dio.dart';
import '../models/landing_page_url_model.dart';

abstract class LandingPageRemoteDataSource {
  Future<LandingPageUrlModel> getLandingPageUrl();
}

class LandingPageRemoteDataSourceImpl implements LandingPageRemoteDataSource {
  final Dio dio;

  LandingPageRemoteDataSourceImpl(this.dio);

  @override
  Future<LandingPageUrlModel> getLandingPageUrl() async {
    final response = await dio.get('/landing-page-url');
    if (response.data['status'] == true) {
      return LandingPageUrlModel.fromJson(response.data['data']);
    }
    throw Exception(response.data['message'] ?? 'Gagal memuat URL landing page');
  }
}
