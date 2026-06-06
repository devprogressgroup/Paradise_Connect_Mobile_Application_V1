class AttendanceEntity {
  final String date;
  final String? clockIn;
  final String? clockOut;
  final String? checkInActivity;
  final String location;
  final List<String>? fileAttchment0;
  final List<String>? fileAttchment1;
  final List<String>? fileAttchment6;
  final String? note0;
  final String? note1;
  final String? note6;
  final String? location0;
  final String? location1;
  final String? location6;
  final String? fullName;
  final int? isApprove0;
  final int? isApprove1;
  final int? isReject0;
  final int? isReject1;
  final bool? needsApproval0;
  final bool? needsApproval1;
  final String? approveName0;
  final String? approveName1;
  final String? rejectName0;
  final String? rejectName1;

  AttendanceEntity({
    required this.date,
    this.clockIn,
    this.clockOut,
    this.checkInActivity,
    required this.location,
    this.fileAttchment0,
    this.fileAttchment1,
    this.fileAttchment6,
    this.note0,
    this.note1,
    this.note6,
    this.location0,
    this.location1,
    this.location6,
    required this.fullName,
    this.isApprove0,
    this.isApprove1,
    this.isReject0,
    this.isReject1,
    this.needsApproval0,
    this.needsApproval1,
    this.approveName0,
    this.approveName1,
    this.rejectName0,
    this.rejectName1,
  });

}