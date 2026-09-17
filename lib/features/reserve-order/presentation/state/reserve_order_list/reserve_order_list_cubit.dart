import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';
import 'reserve_order_list_state.dart';

class ReserveOrderListCubit extends Cubit<ReserveOrderListState> {
  final ReserveOrderRemoteDataSource dataSource;

  static const int perPage = 15;

  ReserveOrderListCubit(this.dataSource) : super(const ReserveOrderListState());

  Future<void> loadFresh({int? contactId}) {
    emit(ReserveOrderListState(
      contactId: contactId,
      filters: state.filters,
      caraBayarOptions: state.caraBayarOptions,
      areaOptions: state.areaOptions,
    ));
    return Future.wait([_loadFilters(), load()]);
  }

  Future<void> _loadFilters() async {
    if (state.filters.isNotEmpty) return;
    try {
      final filters = await dataSource.getReserveFilters();
      emit(state.copyWith(filters: filters));
    } catch (_) {
      // Diamkan — baris chip cuma tidak tampil. Gagal berarti state.filters tetap kosong, jadi
      // percobaan berikutnya (loadFresh/ensureFilters lain) otomatis coba fetch lagi.
    }
  }

  Future<List<ReserveFilterOption>> ensureFilters() async {
    await _loadFilters();
    return state.filters;
  }

  Future<List<ReserveFilterOption>> ensureTransactionTypeFilters() async {
    if (state.transactionTypeFilters.isEmpty) {
      try {
        final filters = await dataSource.getReserveFilters(excludeBatal: true);
        emit(state.copyWith(transactionTypeFilters: filters, transactionTypeFiltersError: null));
      } catch (e) {
        // Pesan aslinya ditumpangkan di state (bukan ditelan diam-diam) supaya `ReservePage`
        // bisa menampilkan pesan sesuai API-nya lengkap dengan tombol "Coba lagi" — lihat
        // `ReserveOrderListState.transactionTypeFiltersError`. Tidak ada fallback lokal lagi.
        emit(state.copyWith(transactionTypeFiltersError: cleanErrorMessage(e)));
      }
    }
    return state.transactionTypeFilters;
  }

  Future<List<CaraBayarOption>> ensureCaraBayarOptions() async {
    if (state.caraBayarOptions.isEmpty) {
      try {
        final options = await dataSource.getCaraBayarOptions();
        emit(state.copyWith(caraBayarOptions: options, caraBayarOptionsError: null));
      } catch (e) {
        // Sama seperti [ensureTransactionTypeFilters] — pesan API-nya ditumpangkan di state,
        // bukan ditelan diam-diam, biar field "Cara Pembarayan" bisa kasih tombol "Coba lagi".
        emit(state.copyWith(caraBayarOptionsError: cleanErrorMessage(e)));
      }
    }
    return state.caraBayarOptions;
  }

  Future<List<AreaOption>> ensureAreaOptions() async {
    if (state.areaOptions.isEmpty) {
      try {
        final options = await dataSource.getAreaOptions();
        emit(state.copyWith(areaOptions: options));
      } catch (_) {
        // Diamkan — dropdown Area cukup menampilkan id mentah (lihat ReserveOrderEditCustomerPage).
      }
    }
    return state.areaOptions;
  }

  Future<void> load({String? search, List<int>? statusIds, String? sort}) async {
    final keyword = search ?? state.search;
    final ids = statusIds ?? state.statusIds;
    final sortValue = sort ?? state.sort;
    final contactId = state.contactId;

    emit(state.copyWith(
      status: ReserveOrderListStatus.loading,
      search: keyword,
      statusIds: ids,
      sort: sortValue,
      contactId: contactId,
      loadingMore: false,
    ));

    try {
      final result = await dataSource.getReserveOrders(
        search: keyword,
        statusReserveIds: ids,
        sort: sortValue,
        contactId: contactId,
        page: 1,
        perPage: perPage,
      );

      emit(state.copyWith(
        status: ReserveOrderListStatus.loaded,
        items: result.items,
        page: result.page,
        hasMore: result.hasMore,
        total: result.total,
        contactId: contactId,
      ));
    } catch (e) {
      emit(state.copyWith(status: ReserveOrderListStatus.error, error: cleanErrorMessage(e), contactId: contactId));
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.status != ReserveOrderListStatus.loaded) return;

    emit(state.copyWith(loadingMore: true, contactId: state.contactId));
    try {
      final result = await dataSource.getReserveOrders(
        search: state.search,
        statusReserveIds: state.statusIds,
        sort: state.sort,
        contactId: state.contactId,
        page: state.page + 1,
        perPage: perPage,
      );

      emit(state.copyWith(
        items: [...state.items, ...result.items],
        page: result.page,
        hasMore: result.hasMore,
        total: result.total,
        loadingMore: false,
        contactId: state.contactId,
      ));
    } catch (_) {
      // Gagal memuat halaman berikutnya tidak mengosongkan daftar yang sudah tampil.
      emit(state.copyWith(loadingMore: false, contactId: state.contactId));
    }
  }

  Future<void> refresh() => load();
}
