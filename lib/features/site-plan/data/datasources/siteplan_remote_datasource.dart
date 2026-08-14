import 'package:dio/dio.dart';

import '../../../../core/network/api_constants.dart';

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

  // TODO: server pricing ini masih vendor internal (IP LAN dev + x-api-key statis) — belum
  // lewat proxy Laravel seperti siteplan-settings/siteplan-proxy di atas. Kalau nanti sudah ada
  // endpoint proxy resminya, ganti pemanggilan ini supaya x-api-key tidak ikut ke-bundle di app.
  static String get _propertyPricingBaseUrl => '${ApiConstants.baseUrl}';
  static const String _propertyPricingApiKey = 'eae3e65103a97623f6b05a75e0fade7c7d2dcffbc3a30f10a6acb33399264a71';

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
    // Dio TERPISAH dari `dio` yang di-inject (itu punya interceptor DioClient yang
    // selalu bungkus request ke /px + header Bearer token punya backend Laravel utama —
    // tidak cocok dipakai ke host vendor pricing ini, yang autentikasinya cuma x-api-key).
    final pricingDio = Dio(
      BaseOptions(
        baseUrl: _propertyPricingBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _propertyPricingApiKey,
        },
      ),
    );
    try {
      final response = await pricingDio.post(
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
