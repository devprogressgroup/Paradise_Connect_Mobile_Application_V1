abstract class ReportEvent {}

class GetVolumeReportEvent extends ReportEvent {
  final String startDate;
  final String endDate;
  final String groupBy;

  GetVolumeReportEvent({required this.startDate, required this.endDate, this.groupBy = 'weekly',});
}