import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/contact/data/datasources/pipeline_remote_datasource.dart';
import 'pipeline_state.dart';


class PipelineCubit extends Cubit<PipelineState> {
  final PipelineRemoteDataSource dataSource;
  List<int>? _statusIds;
  String? _search;

  PipelineCubit(this.dataSource) : super(const PipelineState());

  Future<void> load({List<int>? statusIds, String? search}) async {
    if (statusIds != null) _statusIds = statusIds;
    _search = search;
    emit(state.copyWith(status: PipelineStatus.loading, error: null));
    try {
      final p = await dataSource.getDeals(statusIds: _statusIds, search: _search, page: 1);
      emit(state.copyWith(
        status: PipelineStatus.loaded,
        items: p.items,
        page: p.currentPage,
        lastPage: p.lastPage,
        total: p.total,
      ));
    } catch (e) {
      emit(state.copyWith(status: PipelineStatus.error, error: cleanErrorMessage(e)));
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.status != PipelineStatus.loaded) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final p = await dataSource.getDeals(statusIds: _statusIds, search: _search, page: state.page + 1);
      emit(state.copyWith(
        items: [...state.items, ...p.items],
        page: p.currentPage,
        lastPage: p.lastPage,
        total: p.total,
        loadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> refresh() => load();

  void setSearch(String? value) => load(search: value);
}
