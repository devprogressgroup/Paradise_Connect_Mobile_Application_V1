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

  const ReserveOrderListState({
    this.status = ReserveOrderListStatus.initial,
    this.items = const [],
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
    this.errorMessage,
  });

  bool get hasMore => currentPage < lastPage;

  ReserveOrderListState copyWith({
    ReserveOrderListStatus? status,
    List<ReserveOrderListItemEntity>? items,
    int? currentPage,
    int? lastPage,
    int? total,
    String? errorMessage,
  }) {
    return ReserveOrderListState(
      status: status ?? this.status,
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      errorMessage: errorMessage,
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
  ];
}
