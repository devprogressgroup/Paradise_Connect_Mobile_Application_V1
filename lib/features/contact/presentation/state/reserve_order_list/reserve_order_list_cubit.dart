import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/contact/data/datasources/reserve_order_remote_datasource.dart';
import 'reserve_order_list_state.dart';

/// Daftar transaksi untuk menu "Reserve Order" di drawer (`GET /api/reserve`). Pola sama seperti
/// `ReserveUnitCubit`: datasource langsung, tanpa layer usecase/repository.
class ReserveOrderListCubit extends Cubit<ReserveOrderListState> {
  final ReserveOrderRemoteDataSource dataSource;

  static const int perPage = 15;

  ReserveOrderListCubit(this.dataSource) : super(const ReserveOrderListState());

  /// Memuat halaman pertama. [search] & [statusIds] yang tidak diisi memakai nilai yang sedang
  /// aktif, jadi ganti filter tidak menghapus kata kunci pencarian dan sebaliknya.
  Future<void> load({String? search, List<int>? statusIds}) async {
    final keyword = search ?? state.search;
    final ids = statusIds ?? state.statusIds;

    emit(state.copyWith(
      status: ReserveOrderListStatus.loading,
      search: keyword,
      statusIds: ids,
      loadingMore: false,
    ));

    try {
      final result = await dataSource.getReserveOrders(
        search: keyword,
        statusReserveIds: ids,
        page: 1,
        perPage: perPage,
      );

      emit(state.copyWith(
        status: ReserveOrderListStatus.loaded,
        items: result.items,
        page: result.page,
        hasMore: result.hasMore,
        total: result.total,
      ));
    } catch (e) {
      emit(state.copyWith(status: ReserveOrderListStatus.error, error: cleanErrorMessage(e)));
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.status != ReserveOrderListStatus.loaded) return;

    emit(state.copyWith(loadingMore: true));
    try {
      final result = await dataSource.getReserveOrders(
        search: state.search,
        statusReserveIds: state.statusIds,
        page: state.page + 1,
        perPage: perPage,
      );

      emit(state.copyWith(
        items: [...state.items, ...result.items],
        page: result.page,
        hasMore: result.hasMore,
        total: result.total,
        loadingMore: false,
      ));
    } catch (_) {
      // Gagal memuat halaman berikutnya tidak mengosongkan daftar yang sudah tampil.
      emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> refresh() => load();
}
