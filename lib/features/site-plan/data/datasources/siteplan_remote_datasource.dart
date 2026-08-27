import 'package:dio/dio.dart';

abstract class SiteplanRemoteDataSource {
  Future<Map<String, dynamic>> getSiteplanSettings();

  Future<Map<String, dynamic>> getPropertyPricing({
    required int siteplanId,
    required int companyId,
    required int productId,
    required int propertyId,
  });
}

class SiteplanRemoteDataSourceImpl implements SiteplanRemoteDataSource {
  final Dio dio;
  SiteplanRemoteDataSourceImpl(this.dio);

  @override
  Future<Map<String, dynamic>> getSiteplanSettings() async {
    try {
      final response = await dio.get('/property/siteplan-settings');
      final data = response.data;
      if (data['status'] == true) {
        return Map<String, dynamic>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Gagal mengambil data siteplan');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengambil data siteplan');
    }
  }

  @override
  Future<Map<String, dynamic>> getPropertyPricing({
    required int siteplanId,
    required int companyId,
    required int productId,
    required int propertyId,
  }) async {
    // Lewat `dio` yang di-inject (sama dengan datasource lain) — interceptor DioClient
    // otomatis bungkus request ke /px (AES) + sisipkan Bearer token user login, backend
    // menerimanya lewat middleware thirdparty.apikey_or_jwt (lihat docs/property-pricing-
    // auth-apikey-or-jwt.md di repo Paradise-Connect-1.0).
    try {
      final response = await dio.post(
        '/property-pricing',
        data: {
          'siteplan_id': siteplanId,
          'company_id': companyId,
          'product_id': productId,
          'property_id': propertyId,
        },
      );
      final data = response.data;
      if (data['status'] == true) {
        return Map<String, dynamic>.from(data['data']);
      }
      throw Exception(data['message'] ?? 'Gagal mengambil data harga unit');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengambil data harga unit');
    }
  }
}
