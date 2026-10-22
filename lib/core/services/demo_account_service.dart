import 'package:dio/dio.dart';
import 'package:progress_group/core/network/api_constants.dart';
import 'package:progress_group/core/network/settings_remote_datasource.dart';

/// Akun yang terdaftar di setting DEMO_ACCOUNTS (production) — mis. akun reviewer App Store —
/// login ke server dev, selain itu ke env normal. Ditentukan ulang SETIAP login, jadi apa pun
/// cara sesi sebelumnya berakhir (logout, 401, di-kick), login berikutnya selalu ke server yang benar.
class DemoAccountService {
  static Future<void> routeForLogin(String identifier) async {
    if (!ApiConstants.demoAccountsFresh) {
      // Install baru / /settings production belum sempat ter-fetch (main() tidak menunggunya):
      // tanpa ini akun demo bisa nyasar ke production dan ditolak "password salah". Dio polos,
      // bukan DioClient — /settings publik dan baseUrl-nya harus production, apa pun env aktif.
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.productionBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {'Accept': 'application/json'},
      ));
      final settings = await SettingsRemoteDataSource(dio).getSettings();
      if (settings.isNotEmpty) ApiConstants.applyDemoAccounts(settings);
    }
    await ApiConstants.setDemoSession(ApiConstants.isDemoAccount(identifier));
  }

  static Future<void> endSession() => ApiConstants.setDemoSession(false);
}
