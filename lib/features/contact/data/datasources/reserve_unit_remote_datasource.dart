import 'package:dio/dio.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_option_model.dart';

abstract class ReserveUnitRemoteDataSource {
  Future<UnitOptionsPage> getUnits({
    required int townshipId,
    String? search,
    int page,
    int perPage,
  });
}

class ReserveUnitRemoteDataSourceImpl implements ReserveUnitRemoteDataSource {
  final Dio dio;

  ReserveUnitRemoteDataSourceImpl(this.dio);

  @override
  Future<UnitOptionsPage> getUnits({
    required int townshipId,
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      // Endpoint yang sama dengan unit picker, tapi mode `flat` — daftar kavling se-township yang
      // bisa dicari langsung (blok / no. unit / cluster / tipe), lengkap dengan nama status.
      final response = await dio.get('/property/units/hierarchy', queryParameters: {
        'township_id': townshipId,
        'flat': 1,
        'page': page,
        'per_page': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        final data = Map<String, dynamic>.from(body['data'] as Map);
        final items = (data['units'] as List? ?? [])
            .map((e) => UnitOption.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        return UnitOptionsPage(
          items: items,
          page: data['page'] is int ? data['page'] as int : page,
          hasMore: data['has_more'] == true,
        );
      }
      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat unit') : 'Gagal memuat unit');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat unit'));
    }
  }
}
