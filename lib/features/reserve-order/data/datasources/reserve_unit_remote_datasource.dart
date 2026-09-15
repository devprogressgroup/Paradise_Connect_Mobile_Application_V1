import 'package:dio/dio.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';

abstract class ReserveUnitRemoteDataSource {
  /// Katalog unit yang bisa dipilih (cluster > produk), dari `GET /api/reserve/unit-all?contact_id=…`
  /// — dipakai step "Pilih Unit" di form Reserve buat pilih unit BARU (belum pernah jadi deal).
  Future<List<UnitCluster>> getUnitTree({required int contactId, String? search});

  /// Daftar kavling (+ opsi "belum menentukan kavling"/"waiting list" ditambahkan di UI) satu produk
  /// — endpoint yang sama (`GET /api/reserve/unit-all`) tapi dengan `product_id` dst., dipanggil
  /// begitu produknya di-expand.
  Future<List<UnitLot>> getUnitLots({
    required int productId,
    required int townshipId,
    required int companyId,
    required int contactId,
  });

  /// Deal/unit yang SUDAH ADA buat kontak ini, dari `GET /api/reserve/product-select?contact_id=…`
  /// (`data.units[]`, flat) — dipakai buat auto-centang & menampilkan unit yang sudah dipilih
  /// sebelumnya, terpisah dari katalog [getUnitTree].
  Future<List<SelectedUnit>> getSelectedUnits({required int contactId});
}

class ReserveUnitRemoteDataSourceImpl implements ReserveUnitRemoteDataSource {
  final Dio dio;

  ReserveUnitRemoteDataSourceImpl(this.dio);

  @override
  Future<List<UnitCluster>> getUnitTree({required int contactId, String? search}) async {
    try {
      final response = await dio.get('/reserve/unit-all', queryParameters: {
        'contact_id': contactId,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        final data = Map<String, dynamic>.from(body['data'] as Map);
        final groups = data['data'] as List? ?? [];
        return groups.map((e) => UnitCluster.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat unit') : 'Gagal memuat unit');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat unit'));
    }
  }

  @override
  Future<List<UnitLot>> getUnitLots({
    required int productId,
    required int townshipId,
    required int companyId,
    required int contactId,
  }) async {
    try {
      final response = await dio.get('/reserve/unit-all', queryParameters: {
        'product_id': productId,
        'township_id': townshipId,
        'company_id': companyId,
        'contact_id': contactId,
      });

      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        final data = Map<String, dynamic>.from(body['data'] as Map);
        final lots = data['lots'] as List? ?? [];
        return lots.map((e) => UnitLot.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat kavling') : 'Gagal memuat kavling');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat kavling'));
    }
  }

  @override
  Future<List<SelectedUnit>> getSelectedUnits({required int contactId}) async {
    try {
      final response = await dio.get('/reserve/product-select', queryParameters: {'contact_id': contactId});

      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] is Map) {
        final data = Map<String, dynamic>.from(body['data'] as Map);
        final units = data['units'] as List? ?? [];
        return units.map((e) => SelectedUnit.fromProductSelectJson(Map<String, dynamic>.from(e as Map))).toList();
      }
      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat unit terpilih') : 'Gagal memuat unit terpilih');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat unit terpilih'));
    }
  }
}
