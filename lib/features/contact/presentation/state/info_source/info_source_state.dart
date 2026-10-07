import 'package:equatable/equatable.dart';
import 'package:progress_group/features/contact/domain/entities/info_source/info_source.dart';

enum InfoSourceStatus { initial, loading, loaded, error }

class InfoSourceState extends Equatable {
  final InfoSourceStatus status;
  final List<InfoSource> sources;
  final Map<int, List<InfoSource>> sourcesMap;
  /// sales_channel yang dipakai saat fetch tiap type di [sourcesMap] ('' = tanpa sales_channel).
  /// Bloc ini global, jadi daftar type 2 (Channel Detail) bisa sisa fetch utk channel lain —
  /// form membandingkannya dgn Sales Channel yang sedang dipilih sebelum memakai daftar itu.
  final Map<int, String> channelMap;
  final String? errorMessage;

  const InfoSourceState({
    this.status = InfoSourceStatus.initial,
    this.sources = const [],
    this.sourcesMap = const {},
    this.channelMap = const {},
    this.errorMessage,
  });

  InfoSourceState copyWith({
    InfoSourceStatus? status,
    List<InfoSource>? sources,
    Map<int, List<InfoSource>>? sourcesMap,
    Map<int, String>? channelMap,
    String? errorMessage,
  }) {
    return InfoSourceState(
      status: status ?? this.status,
      sources: sources ?? this.sources,
      sourcesMap: sourcesMap ?? this.sourcesMap,
      channelMap: channelMap ?? this.channelMap,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, sources, sourcesMap, channelMap, errorMessage];
}
