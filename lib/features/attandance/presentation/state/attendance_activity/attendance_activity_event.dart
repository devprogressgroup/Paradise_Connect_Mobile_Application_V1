abstract class AttendanceActivityEvent {}

class ValidasiCheckInEvent extends AttendanceActivityEvent {
  final int logId;
  final int statusValidasi;
  final String? noteValidasi;

  ValidasiCheckInEvent({required this.logId, required this.statusValidasi, this.noteValidasi});
}

class GetAttendanceActivityEvent extends AttendanceActivityEvent {
  final List<int>? salesPersonIds;
  final String? startDate;
  final String? endDate;
  final String? location;
  final int page;
  final int perPage;
  final bool isLoadMore;

  GetAttendanceActivityEvent({
    this.salesPersonIds,
    this.startDate,
    this.endDate,
    this.location,
    this.page = 1,
    this.perPage = 20,
    this.isLoadMore = false,
  });
}
