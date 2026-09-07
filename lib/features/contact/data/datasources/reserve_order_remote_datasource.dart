import 'package:dio/dio.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/contact/data/models/reserve/reserve_order_model.dart';

/// Satu halaman hasil `GET /api/reserve`.
class ReserveOrdersPage {
  final List<ReserveOrder> items;
  final int page;
  final bool hasMore;

  /// Total baris se-query, dipakai untuk teks "N transaksi" di judul list.
  final int total;

  const ReserveOrdersPage({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.total,
  });
}

abstract class ReserveOrderRemoteDataSource {
  Future<ReserveOrdersPage> getReserveOrders({
    String? search,
    List<int> statusReserveIds,
    String sort,
    int page,
    int perPage,
  });
}

class ReserveOrderRemoteDataSourceImpl implements ReserveOrderRemoteDataSource {
  final Dio dio;

  ReserveOrderRemoteDataSourceImpl(this.dio);

  @override
  Future<ReserveOrdersPage> getReserveOrders({
    String? search,
    List<int> statusReserveIds = const [],
    String sort = 'created_desc',
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await dio.get('/reserve', queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        // Server menerima daftar id dipisah koma: `status_reserve_id=1,2`.
        if (statusReserveIds.isNotEmpty) 'status_reserve_id': statusReserveIds.join(','),
        'sort': sort,
        'page': page,
        'per_page': perPage,
      });

      final body = response.data;
      if (body is Map && body['status'] == true && body['data'] != null) {
        final data = Map<String, dynamic>.from(body['data'] as Map);
        final items = (data['data'] as List? ?? [])
            .map((e) => ReserveOrder.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        return ReserveOrdersPage(
          items: items,
          page: data['current_page'] is int ? data['current_page'] as int : page,
          // `next_page_url` null artinya sudah halaman terakhir — dipakai daripada menghitung
          // sendiri dari total/per_page supaya tetap benar kalau server mengubah paginasinya.
          hasMore: data['next_page_url'] != null,
          total: data['total'] is int ? data['total'] as int : items.length,
        );
      }

      throw Exception(body is Map ? (body['message'] ?? 'Gagal memuat reserve order') : 'Gagal memuat reserve order');
    } on DioException catch (e) {
      throw Exception(getErrorMessage(e, 'Gagal memuat reserve order'));
    }
  }
}
