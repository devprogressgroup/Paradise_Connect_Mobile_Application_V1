import '../../domain/entities/attendance_approval_entity.dart';

class AttendanceApprovalModel extends AttendanceApprovalEntity {
  const AttendanceApprovalModel({
    required super.logId,
    super.nikNumber,
    super.attendanceDatetime,
    super.flag,
    super.flagLabel,
    super.locationName,
    super.noteValidasi,
    super.fileAttachment,
    super.fullName,
    super.isApprove,
    super.approveUserId,
    super.approveUsername,
    super.approveName,
    super.approveDatetime,
    super.isReject,
    super.rejectUserId,
    super.rejectUsername,
    super.rejectName,
    super.rejectDatetime,
  });

  factory AttendanceApprovalModel.fromJson(Map<String, dynamic> json) {
    return AttendanceApprovalModel(
      logId: json['log_id'] as int,
      // nik_number bisa int / string → parse aman (NON-SALES pakai app_m_user.nik_number VARCHAR).
      nikNumber: json['nik_number'] == null ? null : int.tryParse(json['nik_number'].toString()),
      attendanceDatetime: json['attendance_datetime'] as String?,
      flag: json['flag'] as int?,
      flagLabel: json['flag_label'] as String?,
      locationName: json['location_name'] as String?,
      noteValidasi: json['note_validasi'] as String?,
      fileAttachment: (json['file_attachment'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      fullName: json['full_name'] as String?,
      isApprove: json['is_approve'] as int?,
      approveUserId: json['approve_user_id'] as int?,
      approveUsername: json['approve_username'] as String?,
      approveName: json['approve_name'] as String?,
      approveDatetime: json['approve_datetime'] as String?,
      isReject: json['is_reject'] as int?,
      rejectUserId: json['reject_user_id'] as int?,
      rejectUsername: json['reject_username'] as String?,
      rejectName: json['reject_name'] as String?,
      rejectDatetime: json['reject_datetime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'log_id': logId,
      'nik_number': nikNumber,
      'attendance_datetime': attendanceDatetime,
      'flag': flag,
      'flag_label': flagLabel,
      'location_name': locationName,
      'note': noteValidasi,
      'file_attachment': fileAttachment,
      'full_name': fullName,
      'is_approve': isApprove,
      'approve_user_id': approveUserId,
      'approve_username': approveUsername,
      'approve_name': approveName,
      'approve_datetime': approveDatetime,
      'is_reject': isReject,
      'reject_user_id': rejectUserId,
      'reject_username': rejectUsername,
      'reject_name': rejectName,
      'reject_datetime': rejectDatetime,
    };
  }
}
