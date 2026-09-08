import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/reserve-order/data/datasources/reserve_unit_remote_datasource.dart';
import 'reserve_unit_state.dart';

/// Daftar kavling untuk step "Pilih Unit" di Reserve Order. Pola sama seperti `PipelineCubit`:
/// datasource langsung, tanpa layer usecase/repository.
class ReserveUnitCubit extends Cubit<ReserveUnitState> {
  final ReserveUnitRemoteDataSource dataSource;

  int? _townshipId;

  ReserveUnitCubit(this.dataSource) : super(const ReserveUnitState());

  Future<void> load({int? townshipId, String? search}) async {
    if (townshipId != null) _townshipId = townshipId;
    final id = _townshipId;
    if (id == null) return;

    final keyword = search ?? state.search;
    emit(state.copyWith(status: ReserveUnitStatus.loading, search: keyword));

    try {
      final result = await dataSource.getUnits(townshipId: id, search: keyword, page: 1);
      emit(state.copyWith(
        status: ReserveUnitStatus.loaded,
        items: result.items,
        page: result.page,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(status: ReserveUnitStatus.error, error: cleanErrorMessage(e)));
    }
  }

  Future<void> loadMore() async {
    final id = _townshipId;
    if (id == null || state.loadingMore || !state.hasMore || state.status != ReserveUnitStatus.loaded) {
      return;
    }

    emit(state.copyWith(loadingMore: true));
    try {
      final result = await dataSource.getUnits(
        townshipId: id,
        search: state.search,
        page: state.page + 1,
      );
      emit(state.copyWith(
        items: [...state.items, ...result.items],
        page: result.page,
        hasMore: result.hasMore,
        loadingMore: false,
      ));
    } catch (_) {
      // Gagal load halaman berikutnya tidak mengosongkan daftar yang sudah tampil.
      emit(state.copyWith(loadingMore: false));
    }
  }

  void setSearch(String value) => load(search: value.trim());
}
