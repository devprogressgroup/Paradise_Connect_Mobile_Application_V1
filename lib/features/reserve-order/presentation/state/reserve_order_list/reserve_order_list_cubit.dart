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

  /// Master status reserve (`GET /api/reserve-filter`) buat chip filter List & "Jenis Transaksi"
  /// di form Reserve — dipakai bareng lewat cubit ini (satu instance, provider bersama di
  /// `main.dart`). Sengaja di-cache di [ReserveOrderListState.filters]: begitu sekali berhasil
  /// dimuat, endpoint ini tidak dipanggil ulang lagi selama cubit-nya belum di-reset (app restart);
  /// [ensureFilters] jadi tempat yang aman dipanggil berkali-kali dari halaman manapun.
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

  /// Dipakai dari luar halaman List (mis. "Jenis Transaksi" di form Reserve) tanpa ikut me-reset
  /// seluruh state list seperti [loadFresh] — cuma mastikan [ReserveOrderListState.filters] terisi
  /// (dari cache kalau sudah ada, atau fetch sekali kalau belum), lalu kembalikan.
  Future<List<ReserveFilterOption>> ensureFilters() async {
    await _loadFilters();
    return state.filters;
  }

  /// Master "Cara Pembayaran" di form Reserve (`GET /api/reserve/cara-bayar`) — pola cache-nya
  /// sama persis dengan [ensureFilters]: dipanggil dari `ReservePage`, tapi cukup sekali fetch
  /// per sesi app selama berhasil.
  Future<List<CaraBayarOption>> ensureCaraBayarOptions() async {
    if (state.caraBayarOptions.isEmpty) {
      try {
        final options = await dataSource.getCaraBayarOptions();
        emit(state.copyWith(caraBayarOptions: options));
      } catch (_) {
        // Diamkan — form Reserve cukup pakai fallback lokalnya (lihat ReservePage).
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

  /// Memuat halaman pertama. [search] & [statusIds] yang tidak diisi memakai nilai yang sedang
  /// aktif, jadi ganti filter tidak menghapus kata kunci pencarian dan sebaliknya. [contactId]
  /// selalu ikut scope yang sedang aktif di state (diisi lewat [loadFresh]).
  Future<void> load({String? search, List<int>? statusIds}) async {
    final keyword = search ?? state.search;
    final ids = statusIds ?? state.statusIds;
    final contactId = state.contactId;

    emit(state.copyWith(
      status: ReserveOrderListStatus.loading,
      search: keyword,
      statusIds: ids,
      contactId: contactId,
      loadingMore: false,
    ));

    try {
      final result = await dataSource.getReserveOrders(
        search: keyword,
        statusReserveIds: ids,
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
