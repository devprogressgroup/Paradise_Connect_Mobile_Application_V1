import 'package:equatable/equatable.dart';
import 'package:progress_group/features/contact/data/models/pipeline/pipeline_deal_model.dart';

enum PipelineStatus { initial, loading, loaded, error }

class PipelineState extends Equatable {
  final PipelineStatus status;
  final List<PipelineDeal> items;
  final int page;
  final int lastPage;
  final int total;
  final bool loadingMore;
  final String? error;

  const PipelineState({
    this.status = PipelineStatus.initial,
    this.items = const [],
    this.page = 1,
    this.lastPage = 1,
    this.total = 0,
    this.loadingMore = false,
    this.error,
  });

  bool get hasMore => page < lastPage;

  PipelineState copyWith({
    PipelineStatus? status,
    List<PipelineDeal>? items,
    int? page,
    int? lastPage,
    int? total,
    bool? loadingMore,
    String? error,
  }) {
    return PipelineState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, items, page, lastPage, total, loadingMore, error];
}
