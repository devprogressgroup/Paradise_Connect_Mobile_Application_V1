class AttendanceActivityVisit {
  final String? datetime;
  final String? lastProject;
  final String? contactName;
  final String? note;
  final List<String>? attachment;

  AttendanceActivityVisit({
    this.datetime,
    this.lastProject,
    this.contactName,
    this.note,
    this.attachment,
  });
}

class AttendanceActivityEntity {
  final String date;
  final int salesPersonId;
  final String fullName;

  final String? clockInDate;
  final String? clockInLocation;
  final String? clockInNote;
  final List<String>? clockInAttachment;

  final String? clockOutDate;
  final String? clockOutLocation;
  final String? clockOutNote;
  final List<String>? clockOutAttachment;

  final String? checkInDate;
  final String? checkInLocation;
  final String? checkInNote;
  final List<String>? checkInAttachment;

  final List<AttendanceActivityVisit> visits;

  AttendanceActivityEntity({
    required this.date,
    required this.salesPersonId,
    required this.fullName,
    this.clockInDate,
    this.clockInLocation,
    this.clockInNote,
    this.clockInAttachment,
    this.clockOutDate,
    this.clockOutLocation,
    this.clockOutNote,
    this.clockOutAttachment,
    this.checkInDate,
    this.checkInLocation,
    this.checkInNote,
    this.checkInAttachment,
    this.visits = const [],
  });
}
