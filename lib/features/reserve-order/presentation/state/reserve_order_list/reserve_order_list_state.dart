import 'package:equatable/equatable.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';

enum ReserveOrderListStatus { initial, loading, loaded, error }

class ReserveOrderListState extends Equatable {
  final ReserveOrderListStatus status;
  final List<ReserveOrder> items;

  /// Halaman terakhir yang berhasil dimuat.
  final int page;
  final bool hasMore;

  /// Total baris se-query dari server — dipakai untuk teks "N transaksi" di judul list.
  final int total;

  final String search;

  /// `status_reserve_id` yang sedang aktif — dikirim ke server sebagai filter.
  final List<int> statusIds;

  /// `sort` yang sedang aktif — salah satu dari `created_asc`, `created_desc`, `name_asc`,
  /// `name_desc`, `amount_desc`, `amount_asc`. Dikirim apa adanya ke `GET /api/reserve`.
  final String sort;

  /// Chip filter dari `GET /api/reserve-filter` (master status reserve). Kosong selagi masih
  /// dimuat atau kalau gagal — chip-nya cuma tidak tampil, tidak memblokir daftar transaksinya.
  final List<ReserveFilterOption> filters;

  /// Master "Jenis Transaksi" di form Reserve — `GET /api/reserve-filter?exclude_batal=1`. Cache
  /// TERPISAH dari [filters] (bukan dipakai ulang) karena query-nya beda: chip filter List butuh
  /// semua status termasuk "Batal", sedang "Jenis Transaksi" tidak boleh menawarkan status "Batal"
  /// sebagai jenis transaksi baru. Lihat `ReserveOrderListCubit.ensureTransactionTypeFilters`.
  final List<ReserveFilterOption> transactionTypeFilters;

  /// Pesan error dari percobaan terakhir [ensureTransactionTypeFilters] (`cleanErrorMessage`) —
  /// null kalau belum pernah dicoba atau percobaan terakhir berhasil. Dibaca `ReservePage` buat
  /// menampilkan pesan asli dari API (bukan fallback lokal) begitu chip "Jenis Transaksi" gagal
  /// dimuat, lengkap dengan tombol "Coba lagi" yang memanggil ulang method yang sama.
  final String? transactionTypeFiltersError;

  /// Master "Cara Pembayaran" di form Reserve, dari `GET /api/reserve/cara-bayar`. Ditumpangkan di
  /// state cubit ini juga (bukan cubit sendiri) supaya cache-nya (lihat
  /// `ReserveOrderListCubit.ensureCaraBayarOptions`) kepakai bareng [filters] — sekali dimuat,
  /// tidak fetch ulang selama cubit-nya (singleton, provider bersama) belum di-reset.
  final List<CaraBayarOption> caraBayarOptions;

  /// Sama seperti [transactionTypeFiltersError] tapi buat [ensureCaraBayarOptions] — dibaca
  /// `ReservePage`/`ReserveOrderEditCustomerPage` buat pesan error field "Tujuan Pembayaran".
  final String? caraBayarOptionsError;

  /// Master "Area" (lokasi/wilayah) di halaman Edit Customer, dari `GET /api/reserve/area` — cache
  /// sama seperti [caraBayarOptions] (lihat `ReserveOrderListCubit.ensureAreaOptions`).
  final List<AreaOption> areaOptions;

  /// Diisi kalau daftar ini sedang disaring buat satu kontak (dibuka dari "Reserve Order" di Log
  /// Activity); null berarti daftar drawer, semua transaksi.
  final int? contactId;

  /// Load halaman berikutnya, dibedakan dari [status] supaya daftar yang sudah tampil tidak
  /// diganti shimmer saat scroll.
  final bool loadingMore;

  final String? error;

  const ReserveOrderListState({
    this.status = ReserveOrderListStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = false,
    this.total = 0,
    this.search = '',
    this.statusIds = const [],
    this.sort = 'created_desc',
    this.filters = const [],
    this.transactionTypeFilters = const [],
    this.transactionTypeFiltersError,
    this.caraBayarOptions = const [],
    this.caraBayarOptionsError,
    this.areaOptions = const [],
    this.contactId,
    this.loadingMore = false,
    this.error,
  });

  ReserveOrderListState copyWith({
    ReserveOrderListStatus? status,
    List<ReserveOrder>? items,
    int? page,
    bool? hasMore,
    int? total,
    String? search,
    List<int>? statusIds,
    String? sort,
    List<ReserveFilterOption>? filters,
    List<ReserveFilterOption>? transactionTypeFilters,
    String? transactionTypeFiltersError,
    List<CaraBayarOption>? caraBayarOptions,
    String? caraBayarOptionsError,
    List<AreaOption>? areaOptions,
    bool? loadingMore,
    String? error,
    int? contactId,
  }) {
    return ReserveOrderListState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
      search: search ?? this.search,
      statusIds: statusIds ?? this.statusIds,
      sort: sort ?? this.sort,
      filters: filters ?? this.filters,
      transactionTypeFilters: transactionTypeFilters ?? this.transactionTypeFilters,
      // Sengaja tidak `?? this.transactionTypeFiltersError` (sama seperti `error`) — begitu
      // [ReserveOrderListCubit.ensureTransactionTypeFilters] dipanggil ulang (retry), errornya
      // mesti reset ke null kalau kali ini berhasil, bukan nyangkut dari percobaan sebelumnya.
      transactionTypeFiltersError: transactionTypeFiltersError,
      caraBayarOptions: caraBayarOptions ?? this.caraBayarOptions,
      // Sama seperti [transactionTypeFiltersError] di atas.
      caraBayarOptionsError: caraBayarOptionsError,
      areaOptions: areaOptions ?? this.areaOptions,
      // Sengaja tidak `?? this.contactId` (sama seperti `error`): tiap pemanggil yang mau
      // mempertahankan scope kontaknya harus mengirim ulang `state.contactId` secara eksplisit,
      // supaya sesi baru (drawer vs. daftar per-kontak) tidak kebawa sisa scope kunjungan sebelumnya.
      contactId: contactId,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        page,
        hasMore,
        total,
        search,
        statusIds,
        sort,
        filters,
        transactionTypeFilters,
        transactionTypeFiltersError,
        caraBayarOptions,
        caraBayarOptionsError,
        areaOptions,
        contactId,
        loadingMore,
        error,
      ];
}
