import 'package:equatable/equatable.dart';
import 'package:progress_group/features/contact/data/models/unit/unit_option_model.dart';

enum ReserveUnitStatus { initial, loading, loaded, error }

class ReserveUnitState extends Equatable {
  final ReserveUnitStatus status;
  final List<UnitOption> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;
  final String search;
  final String? error;

  const ReserveUnitState({
    this.status = ReserveUnitStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = false,
    this.loadingMore = false,
    this.search = '',
    this.error,
  });

  bool get isLoading => status == ReserveUnitStatus.loading;

  ReserveUnitState copyWith({
    ReserveUnitStatus? status,
    List<UnitOption>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? search,
    String? error,
  }) {
    return ReserveUnitState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      search: search ?? this.search,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, items, page, hasMore, loadingMore, search, error];
}
