import 'package:equatable/equatable.dart';
import 'package:progress_group/features/contact/domain/entities/info_source/info_source.dart';

enum InfoSourceStatus { initial, loading, loaded, error }

class InfoSourceState extends Equatable {
  final InfoSourceStatus status;
  final List<InfoSource> sources;
  final Map<int, List<InfoSource>> sourcesMap;
  final String? errorMessage;

  const InfoSourceState({
    this.status = InfoSourceStatus.initial,
    this.sources = const [],
    this.sourcesMap = const {},
    this.errorMessage,
  });

  InfoSourceState copyWith({
    InfoSourceStatus? status,
    List<InfoSource>? sources,
    Map<int, List<InfoSource>>? sourcesMap,
    String? errorMessage,
  }) {
    return InfoSourceState(
      status: status ?? this.status,
      sources: sources ?? this.sources,
      sourcesMap: sourcesMap ?? this.sourcesMap,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, sources, sourcesMap, errorMessage];
}
