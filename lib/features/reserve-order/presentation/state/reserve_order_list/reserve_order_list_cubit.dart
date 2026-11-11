import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/reserve-order/domain/entities/reserve_order_filter_sales_entity.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/get_reserve_order_filter_sales_usecase.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/get_reserve_order_list_usecase.dart';
import 'reserve_order_list_state.dart';

/// State list Reserve Order (`GET /reserve-order/list`) — search, status, sort, dan grup filter
/// "Data Reserve"/"Sales" dari `ContactFilterSheet` (channel/channelDetail/owner/executive/
/// supervisor/manager/gm/team) + Project (nama township) semuanya diteruskan ke server.
///
/// PENTING: [fetch] SELALU dipanggil dengan seluruh filter yang sedang aktif di halaman (bukan
/// patch parsial) — jadi tiap parameter di sini APAPUN nilainya (termasuk null/kosong) langsung
/// jadi nilai baru, TIDAK di-fallback ke nilai lama (`?? _xxx`). Fallback ke nilai lama pernah jadi
/// bug nyata: habis user pencet Reset di sheet filter, `_fetch()` di halaman kirim
/// `statusReserveIds: null` (krn sudah kosong) — tapi `null ?? _statusIds` malah balik ke filter
/// LAMA, jadi query ke server tetap ke-filter walau UI sudah kelihatan "0 filter aktif".
class ReserveOrderListCubit extends Cubit<ReserveOrderListState> {
  final GetReserveOrderListUseCase getReserveOrderListUseCase;
  final GetReserveOrderFilterSalesUseCase getReserveOrderFilterSalesUseCase;

  ReserveOrderListCubit({
    required this.getReserveOrderListUseCase,
    required this.getReserveOrderFilterSalesUseCase,
  }) : super(const ReserveOrderListState());

  /// Pilihan dropdown Sales filter (`GET /reserve-order/filter-sales`). Dipanggil page, hasilnya di-cache
  /// di page; tidak ikut state list karena tidak mempengaruhi query list.
  Future<Either<String, ReserveOrderFilterSalesEntity>> fetchFilterSales() =>
      getReserveOrderFilterSalesUseCase();

  String? _search;
  List<int> _statusIds = const [];
  bool? _rejected;
  /// Param `sort` server (urutan SEPENUHNYA di server): update_terbaru (default) / update_terlama /
  /// dibuat_terbaru / dibuat_terlama / nama_az / nama_za.
  String _sort = 'update_terbaru';
  List<int> _salesChannelIds = const [];
  List<int> _channelDetailIds = const [];
  List<int> _ownerIds = const [];
  List<int> _salesExecutiveIds = const [];
  List<int> _salesSupervisorIds = const [];
  List<int> _salesManagerIds = const [];
  List<int> _generalManagerIds = const [];
  List<int> _salesTeamIds = const [];
  String? _project;

  /// Filter "Progres Akad" (`milestone_id`, tahap setelah SP) & "Persetujuan" (`approval`) — id dari
  /// `filter_options` response list.
  List<int> _milestoneIds = const [];
  List<int> _approvalIds = const [];

  /// `unique_customer=1` — satu baris per customer (RO terbaru tiap customer_id). WAJIB ikut di
  /// refresh & loadMore juga, kalau tidak halaman berikutnya dobel lagi.
  bool _uniqueCustomer = false;

  Future<void> fetch({
    String? search,
    List<int>? statusReserveIds,
    bool? rejected,
    String? sort,
    List<int>? salesChannelIds,
    List<int>? channelDetailIds,
    List<int>? ownerIds,
    List<int>? salesExecutiveIds,
    List<int>? salesSupervisorIds,
    List<int>? salesManagerIds,
    List<int>? generalManagerIds,
    List<int>? salesTeamIds,
    String? project,
    List<int>? milestoneIds,
    List<int>? approvalIds,
    bool uniqueCustomer = false,
  }) async {
    _search = search;
    _statusIds = statusReserveIds ?? const [];
    _rejected = rejected;
    _sort = sort ?? _sort;
    _salesChannelIds = salesChannelIds ?? const [];
    _channelDetailIds = channelDetailIds ?? const [];
    _ownerIds = ownerIds ?? const [];
    _salesExecutiveIds = salesExecutiveIds ?? const [];
    _salesSupervisorIds = salesSupervisorIds ?? const [];
    _salesManagerIds = salesManagerIds ?? const [];
    _generalManagerIds = generalManagerIds ?? const [];
    _salesTeamIds = salesTeamIds ?? const [];
    _project = project;
    _milestoneIds = milestoneIds ?? const [];
    _approvalIds = approvalIds ?? const [];
    _uniqueCustomer = uniqueCustomer;

    emit(state.copyWith(status: ReserveOrderListStatus.loading));

    final result = await getReserveOrderListUseCase(
      search: _search,
      statusReserveIds: _statusIds.isEmpty ? null : _statusIds,
      rejected: _rejected,
      sort: _sort,
      salesChannelIds: _salesChannelIds.isEmpty ? null : _salesChannelIds,
      channelDetailIds: _channelDetailIds.isEmpty ? null : _channelDetailIds,
      ownerIds: _ownerIds.isEmpty ? null : _ownerIds,
      salesExecutiveIds: _salesExecutiveIds.isEmpty ? null : _salesExecutiveIds,
      salesSupervisorIds: _salesSupervisorIds.isEmpty ? null : _salesSupervisorIds,
      salesManagerIds: _salesManagerIds.isEmpty ? null : _salesManagerIds,
      generalManagerIds: _generalManagerIds.isEmpty ? null : _generalManagerIds,
      salesTeamIds: _salesTeamIds.isEmpty ? null : _salesTeamIds,
      project: _project,
      milestoneIds: _milestoneIds.isEmpty ? null : _milestoneIds,
      approvalIds: _approvalIds.isEmpty ? null : _approvalIds,
      uniqueCustomer: _uniqueCustomer,
      page: 1,
    );

    result.fold(
      (message) => emit(
        state.copyWith(
          status: ReserveOrderListStatus.error,
          errorMessage: message,
        ),
      ),
      (data) => emit(
        ReserveOrderListState(
          status: ReserveOrderListStatus.loaded,
          items: data.items,
          currentPage: data.currentPage,
          lastPage: data.lastPage,
          total: data.total,
          // Pilihan filter hanya dikirim di halaman 1; tidak ada → pakai yg sudah tersimpan.
          progressOptions: data.progressOptions ?? state.progressOptions,
          approvalOptions: data.approvalOptions ?? state.approvalOptions,
        ),
      ),
    );
  }

  /// Muat ulang halaman pertama dengan filter/sort terakhir yang dipakai list.
  Future<void> refresh() => fetch(
        search: _search,
        statusReserveIds: _statusIds,
        rejected: _rejected,
        sort: _sort,
        salesChannelIds: _salesChannelIds,
        channelDetailIds: _channelDetailIds,
        ownerIds: _ownerIds,
        salesExecutiveIds: _salesExecutiveIds,
        salesSupervisorIds: _salesSupervisorIds,
        salesManagerIds: _salesManagerIds,
        generalManagerIds: _generalManagerIds,
        salesTeamIds: _salesTeamIds,
        project: _project,
        milestoneIds: _milestoneIds,
        approvalIds: _approvalIds,
        uniqueCustomer: _uniqueCustomer,
      );

  Future<void> loadMore() async {
    if (state.status == ReserveOrderListStatus.loadingMore || !state.hasMore) {
      return;
    }

    emit(state.copyWith(status: ReserveOrderListStatus.loadingMore));

    final result = await getReserveOrderListUseCase(
      search: _search,
      statusReserveIds: _statusIds.isEmpty ? null : _statusIds,
      rejected: _rejected,
      sort: _sort,
      salesChannelIds: _salesChannelIds.isEmpty ? null : _salesChannelIds,
      channelDetailIds: _channelDetailIds.isEmpty ? null : _channelDetailIds,
      ownerIds: _ownerIds.isEmpty ? null : _ownerIds,
      salesExecutiveIds: _salesExecutiveIds.isEmpty ? null : _salesExecutiveIds,
      salesSupervisorIds: _salesSupervisorIds.isEmpty ? null : _salesSupervisorIds,
      salesManagerIds: _salesManagerIds.isEmpty ? null : _salesManagerIds,
      generalManagerIds: _generalManagerIds.isEmpty ? null : _generalManagerIds,
      salesTeamIds: _salesTeamIds.isEmpty ? null : _salesTeamIds,
      project: _project,
      milestoneIds: _milestoneIds.isEmpty ? null : _milestoneIds,
      approvalIds: _approvalIds.isEmpty ? null : _approvalIds,
      uniqueCustomer: _uniqueCustomer,
      page: state.currentPage + 1,
    );

    result.fold(
      (message) => emit(
        state.copyWith(
          status: ReserveOrderListStatus.error,
          errorMessage: message,
        ),
      ),
      (data) => emit(
        state.copyWith(
          status: ReserveOrderListStatus.loaded,
          items: [...state.items, ...data.items],
          currentPage: data.currentPage,
          lastPage: data.lastPage,
          total: data.total,
        ),
      ),
    );
  }
}
