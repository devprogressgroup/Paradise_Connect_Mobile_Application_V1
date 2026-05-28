import 'dart:typed_data';

abstract class AttendanceEvent {}

class GetAttendanceEvent extends AttendanceEvent {
  final List<int>? salesPersonIds;
  GetAttendanceEvent({this.salesPersonIds});
}

class FetchAttendanceDataEvent extends AttendanceEvent {
  final List<int>? salesPersonIds;
  final String? startDate;
  final String? endDate;
  final int page;
  final bool isLoadMore;
  FetchAttendanceDataEvent({this.salesPersonIds, this.startDate, this.endDate, this.page = 1, this.isLoadMore = false});
}

class GetLocationsEvent extends AttendanceEvent {}

class GetOfficeLocationsEvent extends AttendanceEvent {}

class SubmitAttendanceEvent extends AttendanceEvent {
  final String datetime;
  final int flag;
  final String location;
  final String? note;
  final String? filePath;
  final Uint8List? fileBytes;
  final int nikNumber;

  SubmitAttendanceEvent({
    required this.datetime,
    required this.flag,
    required this.location,
    this.note,
    this.filePath,
    this.fileBytes,
    required this.nikNumber,
  });
}

class SubmitAttendanceActivityEvent extends AttendanceEvent {
  final String datetime;
  final int flag;
  final String location;
  final String? note;
  final List<String> filePaths;
  final List<Uint8List>? fileBytesData;
  final int nikNumber;

  SubmitAttendanceActivityEvent({
    required this.datetime,
    required this.flag,
    required this.location,
    this.note,
    required this.filePaths,
    this.fileBytesData,
    required this.nikNumber,
  });
}
