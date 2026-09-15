import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_order_remote_datasource.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';
import 'reserve_order_list_state.dart';

/// Daftar transaksi untuk menu "Reserve Order" di drawer (`GET /api/reserve`). Pola sama seperti
/// `ReserveUnitCubit`: datasource langsung, tanpa layer usecase/repository.
class ReserveOrderListCubit extends Cubit<ReserveOrderListState> {
  final ReserveOrderRemoteDataSource dataSource;

  static const int perPage = 15;

  ReserveOrderListCubit(this.dataSource) : super(const ReserveOrderListState());

  /// Dipanggil sekali di awal halaman, sebelum [load] — cubit ini dipakai bersama drawer (semua
  /// transaksi) & daftar per-kontak (disaring [contactId]), jadi state-nya di-reset dulu supaya
  /// sisa scope/pencarian dari kunjungan sebelumnya tidak kebawa ke sesi baru. [filters],
  /// [caraBayarOptions] & [areaOptions] sengaja dipertahankan dari state sebelumnya (lihat
  /// [ensureFilters] / [ensureCaraBayarOptions] / [ensureAreaOptions]) — bukan bagian dari scope
  /// yang mesti direset per kunjungan.
  Future<void> loadFresh({int? contactId}) {
    emit(ReserveOrderListState(
      contactId: contactId,
      filters: state.filters,
      caraBayarOptions: state.caraBayarOptions,
      areaOptions: state.areaOptions,
    ));
    return Future.wait([_loadFilters(), load()]);
  }

  /// Master status reserve (`GET /api/reserve-filter`, semua status) buat chip filter di atas list.
  /// "Jenis Transaksi" di form Reserve pakai query berbeda (`exclude_batal=1`) lewat
  /// [ensureTransactionTypeFilters] & cache terpisah — TIDAK numpang di sini. Sengaja di-cache di
  /// [ReserveOrderListState.filters]: begitu sekali berhasil dimuat, endpoint ini tidak dipanggil
  /// ulang lagi selama cubit-nya belum di-reset (app restart); [ensureFilters] jadi tempat yang aman
  /// dipanggil berkali-kali dari halaman manapun.
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

  /// Dipakai dari luar halaman List (chip filter atas list) tanpa ikut me-reset seluruh state list
  /// seperti [loadFresh] — cuma mastikan [ReserveOrderListState.filters] terisi (dari cache kalau
  /// sudah ada, atau fetch sekali kalau belum), lalu kembalikan.
  Future<List<ReserveFilterOption>> ensureFilters() async {
    await _loadFilters();
    return state.filters;
  }

  /// Master "Jenis Transaksi" di form Reserve — `GET /api/reserve-filter?exclude_batal=1`. Cache
  /// TERPISAH dari [ensureFilters] (lihat [ReserveOrderListState.transactionTypeFilters]): query-nya
  /// beda, jadi tidak bisa numpang cache [_loadFilters]. Pola cache-nya sama — sekali berhasil
  /// dimuat, tidak fetch ulang lagi selama cubit-nya belum di-reset.
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

  /// Master "Cara Pembayaran" di form Reserve (`GET /api/reserve/cara-bayar`) — pola cache-nya
  /// sama persis dengan [ensureFilters]: dipanggil dari `ReservePage`, tapi cukup sekali fetch
  /// per sesi app selama berhasil.
  Future<List<CaraBayarOption>> ensureCaraBayarOptions() async {
    if (state.caraBayarOptions.isEmpty) {
      try {
        final options = await dataSource.getCaraBayarOptions();
        emit(state.copyWith(caraBayarOptions: options, caraBayarOptionsError: null));
      } catch (e) {
        // Sama seperti [ensureTransactionTypeFilters] — pesan API-nya ditumpangkan di state,
        // bukan ditelan diam-diam, biar field "Tujuan Pembayaran" bisa kasih tombol "Coba lagi".
        emit(state.copyWith(caraBayarOptionsError: cleanErrorMessage(e)));
      }
    }
    return state.caraBayarOptions;
  }

  /// Master "Area" (lokasi/wilayah) di halaman Edit Customer (`GET /api/reserve/area`) — pola
  /// cache-nya sama persis dengan [ensureCaraBayarOptions].
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

  /// Memuat halaman pertama. [search], [statusIds] & [sort] yang tidak diisi memakai nilai yang
  /// sedang aktif, jadi ganti satu filter tidak menghapus yang lain. [contactId] selalu ikut scope
  /// yang sedang aktif di state (diisi lewat [loadFresh]).
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
