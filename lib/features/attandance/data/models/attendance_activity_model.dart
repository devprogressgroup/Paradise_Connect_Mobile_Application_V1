import 'package:progress_group/features/attandance/domain/entities/attendance_activity_entity.dart';

class AttendanceActivityModel extends AttendanceActivityEntity {
  AttendanceActivityModel({
    required super.userId,
    required super.salesPersonId,
    required super.fullName,
    super.photoUrl,
    required super.activityType,
    required super.activityDatetime,
    super.activityId,
    super.logId,
    super.contactId,
    super.contactName,
    super.projectName,
    super.location,
    super.note,
    super.statusValidasi,
    super.statusValidasiLabel,
    super.noteValidasi,
    super.isApprove,
    super.approveUserId,
    super.approveDatetime,
    super.attachments,
  });

  factory AttendanceActivityModel.fromJson(Map<String, dynamic> json) {
    return AttendanceActivityModel(
      userId: json['user_id'] ?? 0,
      salesPersonId: json['sales_person_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      photoUrl: json['photo_url'],
      activityType: json['activity_type'] ?? '',
      activityDatetime: json['activity_datetime'] ?? '',
      activityId: json['activity_id'],
      logId: json['log_id'],
      contactId: json['contact_id'],
      contactName: json['contact_name'],
      projectName: json['project_name'],
      location: json['location'],
      note: json['note'],
      statusValidasi: json['status_validasi'],
      statusValidasiLabel: json['status_validasi_label'],
      noteValidasi: json['note_validasi'],
      isApprove: json['is_approve'],
      approveUserId: json['approve_user_id'],
      approveDatetime: json['approve_datetime'],
      attachments: json['attachments'] != null ? List<String>.from(json['attachments']) : [],
    );
  }
}
