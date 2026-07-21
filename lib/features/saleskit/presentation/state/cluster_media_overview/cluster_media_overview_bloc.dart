import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/saleskit/domain/usecase/get_cluster_media_usecase.dart';
import 'package:progress_group/features/saleskit/domain/usecase/share_caption_usecase.dart';
import 'cluster_media_overview_event.dart';
import 'cluster_media_overview_state.dart';
import 'media_group_section.dart';

const int kMediaSectionPerPage = 10;
const int _discoveryPerPage = 50;

class ClusterMediaOverviewBloc extends Bloc<ClusterMediaOverviewEvent, ClusterMediaOverviewState> {
  final GetClusterMediaUseCase getClusterMediaUseCase;
  final ShareCaptionUseCase shareCaptionUseCase;

  ClusterMediaOverviewBloc(this.getClusterMediaUseCase, this.shareCaptionUseCase) : super(ClusterMediaOverviewInitial()) {
    on<LoadClusterMediaOverviewEvent>(_onLoad, transformer: restartable());
    on<LoadMoreGroupMediaEvent>(_onLoadMore, transformer: sequential());
  }

  Future<void> _onLoad(LoadClusterMediaOverviewEvent event, Emitter<ClusterMediaOverviewState> emit) async {
    emit(ClusterMediaOverviewLoading());
    try {
      final discovery = await getClusterMediaUseCase(GetClusterMediaParams(
        clusterId: event.clusterId,
        ownerType: event.ownerType,
        page: 1,
        perPage: _discoveryPerPage,
      ));

      final groupOrder = <int, String>{};
      for (final item in discovery.items) {
        groupOrder.putIfAbsent(item.mediaGroupId, () => item.groupName);
      }

      final sections = await Future.wait(groupOrder.entries.map((entry) async {
        final page = await getClusterMediaUseCase(GetClusterMediaParams(
          clusterId: event.clusterId,
          ownerType: event.ownerType,
          mediaGroupId: entry.key,
          page: 1,
          perPage: kMediaSectionPerPage,
        ));
        return MediaGroupSection(
          mediaGroupId: entry.key,
          groupName: entry.value,
          items: page.items,
          currentPage: page.pagination.currentPage,
          lastPage: page.pagination.lastPage,
        );
      }));

      emit(ClusterMediaOverviewLoaded(clusterId: event.clusterId, ownerType: event.ownerType, sections: sections));
    } catch (e) {
      emit(ClusterMediaOverviewError(cleanErrorMessage(e)));
    }
  }

  Future<void> _onLoadMore(LoadMoreGroupMediaEvent event, Emitter<ClusterMediaOverviewState> emit) async {
    final current = state;
    if (current is! ClusterMediaOverviewLoaded ||
        current.clusterId != event.clusterId ||
        current.ownerType != event.ownerType) {
      return;
    }

    final index = current.sections.indexWhere((s) => s.mediaGroupId == event.mediaGroupId);
    if (index == -1) return;
    final section = current.sections[index];
    if (!section.hasMore || section.isLoadingMore) return;

    List<MediaGroupSection> replaceSection(MediaGroupSection updated) {
      final latest = state;
      final base = latest is ClusterMediaOverviewLoaded &&
              latest.clusterId == event.clusterId &&
              latest.ownerType == event.ownerType
          ? latest.sections
          : current.sections;
      return base.map((s) => s.mediaGroupId == event.mediaGroupId ? updated : s).toList();
    }

    emit(ClusterMediaOverviewLoaded(
      clusterId: event.clusterId,
      ownerType: event.ownerType,
      sections: replaceSection(section.copyWith(isLoadingMore: true)),
    ));

    try {
      final nextPage = await getClusterMediaUseCase(GetClusterMediaParams(
        clusterId: event.clusterId,
        ownerType: event.ownerType,
        mediaGroupId: event.mediaGroupId,
        page: section.currentPage + 1,
        perPage: kMediaSectionPerPage,
      ));
      final updated = section.copyWith(
        items: [...section.items, ...nextPage.items],
        currentPage: nextPage.pagination.currentPage,
        lastPage: nextPage.pagination.lastPage,
        isLoadingMore: false,
      );
      emit(ClusterMediaOverviewLoaded(
        clusterId: event.clusterId,
        ownerType: event.ownerType,
        sections: replaceSection(updated),
      ));
    } catch (_) {
      emit(ClusterMediaOverviewLoaded(
        clusterId: event.clusterId,
        ownerType: event.ownerType,
        sections: replaceSection(section.copyWith(isLoadingMore: false)),
      ));
    }
  }
}
