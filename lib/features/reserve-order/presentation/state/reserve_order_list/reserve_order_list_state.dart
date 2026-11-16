import 'package:equatable/equatable.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_list_item_entity.dart';

enum ReserveOrderListStatus { initial, loading, loadingMore, loaded, error }

class ReserveOrderListState extends Equatable {
  final ReserveOrderListStatus status;
  final List<ReserveOrderListItemEntity> items;
  final int currentPage;
  final int lastPage;
  final int total;
  final String? errorMessage;

  /// Pilihan filter "Progres Akad" & "Persetujuan" dari server (`filter_options`, halaman 1) — disimpan
  /// supaya sheet Filter tetap punya pilihan walau fetch berikutnya gagal / halaman lanjutan tidak membawanya.
  final List<ReserveOrderFilterOptionEntity> progressOptions;
  final List<ReserveOrderFilterOptionEntity> approvalOptions;

  const ReserveOrderListState({
    this.status = ReserveOrderListStatus.initial,
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.errorMessage,
    this.progressOptions = const [],
    this.approvalOptions = const [],
  });

  bool get hasMore => currentPage < lastPage;

  ReserveOrderListState copyWith({
    ReserveOrderListStatus? status,
    List<ReserveOrderListItemEntity>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    String? errorMessage,
    List<ReserveOrderFilterOptionEntity>? progressOptions,
    List<ReserveOrderFilterOptionEntity>? approvalOptions,
  }) {
    return ReserveOrderListState(
      status: status ?? this.status,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      errorMessage: errorMessage,
      progressOptions: progressOptions ?? this.progressOptions,
      approvalOptions: approvalOptions ?? this.approvalOptions,
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    currentPage,
    lastPage,
    total,
    errorMessage,
    progressOptions,
    approvalOptions,
  ];
}
