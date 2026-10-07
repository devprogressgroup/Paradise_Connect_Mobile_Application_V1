import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/contact/domain/entities/info_source/info_source.dart';
import 'package:progress_group/features/contact/domain/usecases/info_source/get_info_sources_usecase.dart';
import 'info_source_event.dart';
import 'info_source_state.dart';

class InfoSourceBloc extends Bloc<InfoSourceEvent, InfoSourceState> {
  final GetInfoSourcesUseCase getInfoSourcesUseCase;

  InfoSourceBloc({required this.getInfoSourcesUseCase}) : super(const InfoSourceState()) {
    on<FetchInfoSourcesEvent>(_onFetchInfoSources);
    on<ResetInfoSourcesEvent>(_onResetInfoSources);
  }

  void _onResetInfoSources(
    ResetInfoSourcesEvent event,
    Emitter<InfoSourceState> emit,
  ) {
    final newSourcesMap = Map<int, List<InfoSource>>.from(state.sourcesMap);
    final newChannelMap = Map<int, String>.from(state.channelMap);
    for (final type in event.types) {
      newSourcesMap.remove(type);
      newChannelMap.remove(type);
    }
    emit(state.copyWith(sourcesMap: newSourcesMap, channelMap: newChannelMap));
  }

  Future<void> _onFetchInfoSources(
    FetchInfoSourcesEvent event,
    Emitter<InfoSourceState> emit,
  ) async {
    emit(state.copyWith(status: InfoSourceStatus.loading));

    final result = await getInfoSourcesUseCase(type: event.type, userId: event.userId, salesChannel: event.salesChannel, all: event.all);

    result.fold(
      (failure) => emit(state.copyWith(
        status: InfoSourceStatus.error,
        errorMessage: failure,
      )),
      (sources) {
        final newSourcesMap = Map<int, List<InfoSource>>.from(state.sourcesMap);
        final newChannelMap = Map<int, String>.from(state.channelMap);
        if (event.type != null) {
          newSourcesMap[event.type!] = sources;
          newChannelMap[event.type!] = event.salesChannel ?? '';
        }

        emit(state.copyWith(
          status: InfoSourceStatus.loaded,
          sources: sources,
          sourcesMap: newSourcesMap,
          channelMap: newChannelMap,
        ));
      },
    );
  }
}
