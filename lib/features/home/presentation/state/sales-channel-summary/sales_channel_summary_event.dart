abstract class SalesChannelSummaryEvent {}

class FetchSalesChannelsSummaryEvent extends SalesChannelSummaryEvent {
  final String? startDate;
  final String? endDate;

  FetchSalesChannelsSummaryEvent({this.startDate, this.endDate});
}
