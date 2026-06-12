import 'package:progress_group/core/network/api_constants.dart';
import '../models/landing_page_url_model.dart';

abstract class LandingPageRemoteDataSource {
  Future<LandingPageUrlModel> getLandingPageUrl();
}

class LandingPageRemoteDataSourceImpl implements LandingPageRemoteDataSource {
  @override
  Future<LandingPageUrlModel> getLandingPageUrl() async {
    final url = ApiConstants.landingPageUrl;
    if (url.isEmpty) throw Exception('URL landing page belum tersedia');
    return LandingPageUrlModel(landingPageUrl: url);
  }
}
