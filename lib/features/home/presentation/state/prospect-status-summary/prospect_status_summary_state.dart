import 'package:progress_group/features/home/domain/entities/prospect_status_summary_entity.dart';

enum ProspectStatusSummaryStatus { initial, loading, loaded, error }

class ProspectStatusSummaryState {
  final ProspectStatusSummaryStatus status;
  final ProspectStatusSummaryEntity? summary;
  final String? errorMessage;

  const ProspectStatusSummaryState({
    this.status = ProspectStatusSummaryStatus.initial,
    this.summary,
    this.errorMessage,
  });

  ProspectStatusSummaryState copyWith({
    ProspectStatusSummaryStatus? status,
    ProspectStatusSummaryEntity? summary,
    String? errorMessage,
  }) {
    return ProspectStatusSummaryState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
