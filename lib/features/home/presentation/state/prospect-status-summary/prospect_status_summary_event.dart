abstract class ProspectStatusSummaryEvent {}

class FetchProspectStatusSummaryEvent extends ProspectStatusSummaryEvent {
  final String? startDate;
  final String? endDate;

  FetchProspectStatusSummaryEvent({this.startDate, this.endDate});
}
