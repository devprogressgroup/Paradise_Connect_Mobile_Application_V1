import 'package:equatable/equatable.dart';
import 'package:progress_group/features/contact/data/models/reserve/reserve_order_model.dart';

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

  /// `status_reserve_id` yang sedang aktif. Masih kosong sampai endpoint master statusnya ada.
  final List<int> statusIds;

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
    bool? loadingMore,
    String? error,
  }) {
    return ReserveOrderListState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      total: total ?? this.total,
      search: search ?? this.search,
      statusIds: statusIds ?? this.statusIds,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, items, page, hasMore, total, search, statusIds, loadingMore, error];
}
