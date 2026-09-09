import 'package:dio/dio.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_hierarchy_model.dart';

/// Satu halaman hasil `GET /api/reserve/unit-status`.
class ReserveUnitsPage {
  final List<SelectedUnit> items;
  final int page;
  final bool hasMore;

  const ReserveUnitsPage({required this.items, required this.page, required this.hasMore});
}

abstract class ReserveUnitRemoteDataSource {
  /// Daftar unit (satu baris per deal) milik satu kontak, bisa dicari & di-paginasi — dipakai step
  /// "Pilih Unit" di form Reserve.
  Future<ReserveUnitsPage> getUnits({
    required int contactId,
    String? search,
    String sort,
    int page,
    int perPage,
  });
}

class ReserveUnitRemoteDataSourceImpl implements ReserveUnitRemoteDataSource {
  final Dio dio;

  ReserveUnitRemoteDataSourceImpl(this.dio);

  @override
  Future<ReserveUnitsPage> getUnits({
    required int contactId,
    String? search,
    String sort = 'created_desc',
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await dio.get('/reserve/unit-status', queryParameters: {
        'contact_id': contactId,
        'sort': sort,
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        final data = Map<String, dynamic>.from(body['data'] as Map);
        // `data.data` — paginator Laravel standar (sama seperti `GET /api/reserve`, bukan bentuk
        // custom `units`/`page`/`has_more` yang dipakai endpoint hierarchy unit yang lama).
        final items = (data['data'] as List? ?? [])
            .map((e) => SelectedUnit.fromUnitStatusJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        return ReserveUnitsPage(
          items: items,
          page: data['current_page'] is int ? data['current_page'] as int : page,
          hasMore: data['next_page_url'] != null,
        );
      }
      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat unit') : 'Gagal memuat unit');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat unit'));
    }
  }
}
