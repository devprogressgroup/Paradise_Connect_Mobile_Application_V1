import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/contact/data/models/ktp/ktp_ocr_model.dart';

abstract class KtpOcrRemoteDataSource {
  Future<KtpOcrModel> scanKtp({required Uint8List bytes, required String fileName});
}

class KtpOcrRemoteDataSourceImpl implements KtpOcrRemoteDataSource {
  final Dio dio;

  KtpOcrRemoteDataSourceImpl(this.dio);

  // OCR dijalankan di server (Google Cloud Vision, lihat App\Services\KtpOcrService di backend)
  // supaya satu jalur ini dipakai PWA web maupun mobile — ML Kit tidak punya implementasi web,
  // dan API key OCR pihak ketiga tidak boleh ikut ke-bundle di JS.
  static const String endpoint = '/reserve/ktp-ocr';

  @override
  Future<KtpOcrModel> scanKtp({required Uint8List bytes, required String fileName}) async {
    try {
      // Kirim bytes (bukan path) supaya sama persis jalannya di web & mobile — PickedFileResult
      // dari CustomFilePicker selalu mengisi bytes, sedangkan path null di web.
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await dio.post(endpoint, data: formData);
      final body = response.data;

      if (body is Map && body['status'] == true && body['data'] != null) {
        final data = Map<String, dynamic>.from(body['data'] as Map);

        // Server memisahkan `fields` (nama kolom m_customer_reserve, siap dikirim balik ke
        // POST /api/reserve) dari `ktp` (data KTP yang tidak punya kolom sendiri: kecamatan,
        // kel/desa, RT/RW, dll). Digabung di sini supaya model cukup satu peta datar.
        final fields = (data['fields'] as Map?)?.cast<String, dynamic>() ?? const {};
        final ktp = (data['ktp'] as Map?)?.cast<String, dynamic>() ?? const {};
        final merged = <String, dynamic>{...fields, ...ktp};

        return KtpOcrModel.fromJson(merged.isEmpty ? data : merged);
      }
      throw Exception(body is Map ? (body['message'] ?? 'Gagal membaca KTP') : 'Gagal membaca KTP');
    } on DioException catch (e) {
      // 404/405/501 = endpoint-nya belum ada di server yang dipakai (mis. backend belum
      // di-deploy) → jangan tampilkan error mentah, arahkan ke isi manual. Untuk 503 server
      // sudah mengirim pesan yang jelas sendiri (Vision belum aktif / kuota), jadi dipakai
      // apa adanya lewat getErrorMessage.
      final code = e.response?.statusCode;
      if (code == 404 || code == 405 || code == 501) {
        throw Exception('Scan OCR KTP belum tersedia di server. Silakan isi data manual.');
      }
      throw Exception(getErrorMessage(e, 'Gagal membaca KTP'));
    }
  }
}
