import 'package:equatable/equatable.dart';
import 'package:progress_group/features/reserve-order/data/models/reserve_order_model.dart';

enum ReserveOrderListStatus { initial, loading, loaded, error }

class ReserveOrderListState extends Equatable {
  final ReserveOrderListStatus status;
  final List<ReserveOrder> items;
  final int page;
  final bool hasMore;
  final int total;

  final String search;
  final List<int> statusIds;
  final String sort;
  final List<ReserveFilterOption> filters;
  final List<ReserveFilterOption> transactionTypeFilters;
  final String? transactionTypeFiltersError;
  final List<CaraBayarOption> caraBayarOptions;
  final String? caraBayarOptionsError;
  final List<AreaOption> areaOptions;
  final int? contactId;
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
