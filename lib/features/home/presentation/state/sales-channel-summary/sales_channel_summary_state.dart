import 'package:progress_group/features/home/domain/entities/sales_channel_summary_entity.dart';

enum SalesChannelSummaryStatus { initial, loading, loaded, error }

class SalesChannelSummaryState {
  final SalesChannelSummaryStatus status;
  final SalesChannelSummaryEntity? summary;
  final String? errorMessage;

  const SalesChannelSummaryState({
    this.status = SalesChannelSummaryStatus.initial,
    this.summary,
    this.errorMessage,
  });

  SalesChannelSummaryState copyWith({
    SalesChannelSummaryStatus? status,
    SalesChannelSummaryEntity? summary,
    String? errorMessage,
  }) {
    return SalesChannelSummaryState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
