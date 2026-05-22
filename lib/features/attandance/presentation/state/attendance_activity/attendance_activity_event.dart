abstract class AttendanceActivityEvent {}

class GetAttendanceActivityEvent extends AttendanceActivityEvent {
  final List<int>? salesPersonIds;
  final String? startDate;
  final String? endDate;
  final String? location;
  final int page;
  final bool isLoadMore;

  GetAttendanceActivityEvent({
    this.salesPersonIds,
    this.startDate,
    this.endDate,
    this.location,
    this.page = 1,
    this.isLoadMore = false,
  });
}
