class AttendanceActivityEntity {
  final int userId;
  final int salesPersonId;
  final String fullName;
  final String? photoUrl;
  final String activityType;
  final String activityDatetime;
  final int? activityId;
  final int? logId;
  final int? contactId;
  final String? contactName;
  final String? projectName;
  final String? location;
  final String? note;
  final int? statusValidasi;
  final String? statusValidasiLabel;
  final String? noteValidasi;
  final int? isApprove;
  final int? approveUserId;
  final String? approveDatetime;
  final List<String> attachments;

  AttendanceActivityEntity({
    required this.userId,
    required this.salesPersonId,
    required this.fullName,
    this.photoUrl,
    required this.activityType,
    required this.activityDatetime,
    this.activityId,
    this.logId,
    this.contactId,
    this.contactName,
    this.projectName,
    this.location,
    this.note,
    this.statusValidasi,
    this.statusValidasiLabel,
    this.noteValidasi,
    this.isApprove,
    this.approveUserId,
    this.approveDatetime,
    this.attachments = const [],
  });

  String get date => activityDatetime.split(' ').first;

  AttendanceActivityEntity copyWith({
    int? statusValidasi,
    String? statusValidasiLabel,
    String? noteValidasi,
  }) {
    return AttendanceActivityEntity(
      userId: userId,
      salesPersonId: salesPersonId,
      fullName: fullName,
      photoUrl: photoUrl,
      activityType: activityType,
      activityDatetime: activityDatetime,
      activityId: activityId,
      logId: logId,
      contactId: contactId,
      contactName: contactName,
      projectName: projectName,
      location: location,
      note: note,
      statusValidasi: statusValidasi ?? this.statusValidasi,
      statusValidasiLabel: statusValidasiLabel ?? this.statusValidasiLabel,
      noteValidasi: noteValidasi ?? this.noteValidasi,
      isApprove: isApprove,
      approveUserId: approveUserId,
      approveDatetime: approveDatetime,
      attachments: attachments,
    );
  }
}
