import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/saleskit/domain/usecase/get_cluster_media_usecase.dart';
import 'package:progress_group/features/saleskit/domain/usecase/share_caption_usecase.dart';
import 'cluster_media_list_event.dart';
import 'cluster_media_list_state.dart';

const int kMediaListPerPage = 10;

class ClusterMediaListBloc extends Bloc<ClusterMediaListEvent, ClusterMediaListState> {
  final GetClusterMediaUseCase getClusterMediaUseCase;
  final ShareCaptionUseCase shareCaptionUseCase;

  ClusterMediaListBloc(this.getClusterMediaUseCase, this.shareCaptionUseCase) : super(ClusterMediaListInitial()) {
    on<LoadClusterMediaListEvent>(_onLoad, transformer: restartable());
    on<LoadMoreClusterMediaListEvent>(_onLoadMore, transformer: sequential());
  }

  Future<void> _onLoad(LoadClusterMediaListEvent event, Emitter<ClusterMediaListState> emit) async {
    emit(ClusterMediaListLoading());
    try {
      final page = await getClusterMediaUseCase(GetClusterMediaParams(
        clusterId: event.clusterId,
        ownerType: event.ownerType,
        mediaGroupId: event.mediaGroupId,
        search: event.search,
        sortBy: event.sortBy,
        sortDir: event.sortDir,
        page: 1,
        perPage: kMediaListPerPage,
      ));
      emit(ClusterMediaListLoaded(
        clusterId: event.clusterId,
        ownerType: event.ownerType,
        mediaGroupId: event.mediaGroupId,
        search: event.search,
        sortBy: event.sortBy,
        sortDir: event.sortDir,
        items: page.items,
        currentPage: page.pagination.currentPage,
        lastPage: page.pagination.lastPage,
      ));
    } catch (e) {
      emit(ClusterMediaListError(cleanErrorMessage(e)));
    }
  }

  Future<void> _onLoadMore(LoadMoreClusterMediaListEvent event, Emitter<ClusterMediaListState> emit) async {
    final current = state;
    if (current is! ClusterMediaListLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));
    try {
      final page = await getClusterMediaUseCase(GetClusterMediaParams(
        clusterId: current.clusterId,
        ownerType: current.ownerType,
        mediaGroupId: current.mediaGroupId,
        search: current.search,
        sortBy: current.sortBy,
        sortDir: current.sortDir,
        page: current.currentPage + 1,
        perPage: kMediaListPerPage,
      ));
      final latest = state;
      if (latest is! ClusterMediaListLoaded) return;
      emit(latest.copyWith(
        items: [...latest.items, ...page.items],
        currentPage: page.pagination.currentPage,
        lastPage: page.pagination.lastPage,
        isLoadingMore: false,
      ));
    } catch (_) {
      final latest = state;
      if (latest is ClusterMediaListLoaded) {
        emit(latest.copyWith(isLoadingMore: false));
      }
    }
  }
}
