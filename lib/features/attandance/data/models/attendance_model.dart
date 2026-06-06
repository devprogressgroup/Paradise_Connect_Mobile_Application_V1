import 'package:progress_group/features/attandance/domain/entities/attandance_entity.dart';

class AttendanceModel extends AttendanceEntity {
  AttendanceModel({
    required super.date,
    super.clockIn,
    super.clockOut,
    super.checkInActivity,
    required super.location,
    super.fileAttchment0,
    super.fileAttchment1,
    super.fileAttchment6,
    super.note0,
    super.note1,
    super.note6,
    super.location0,
    super.location1,
    super.location6,
    super.fullName,
    super.isApprove0,
    super.isApprove1,
    super.isReject0,
    super.isReject1,
    super.needsApproval0,
    super.needsApproval1,
    super.approveName0,
    super.approveName1,
    super.rejectName0,
    super.rejectName1,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    final bool isClockIn = json['clockIn_date'] != null;
    final isApproveRaw = json['is_approve'];
    final isApproveInt = isApproveRaw is int ? isApproveRaw : int.tryParse(isApproveRaw?.toString() ?? '');
    final isRejectRaw = json['is_reject'];
    final isRejectInt = isRejectRaw is int ? isRejectRaw : int.tryParse(isRejectRaw?.toString() ?? '');
    final needsApprovalBool = json['needs_approval'] as bool? ?? false;
    final approveName = json['approve_name'] as String?;
    final rejectName = json['reject_name'] as String?;

    return AttendanceModel(
      date: json['date'] ?? '',
      clockIn: json['clockIn_date'],
      clockOut: json['clockOut_date'],
      checkInActivity: json['checkIn_date_activity'],
      location: json['location_flag_0'] ?? json['location_name'] ?? '',
      fileAttchment0: json['file_attachment_flag_0'] != null ? List<String>.from(json['file_attachment_flag_0']) : null,
      fileAttchment1: json['file_attachment_flag_1'] != null ? List<String>.from(json['file_attachment_flag_1']) : null,
      fileAttchment6: json['file_attachment_flag_6'] != null ? List<String>.from(json['file_attachment_flag_6']) : null,
      note0: json['note_flag_0'],
      note1: json['note_flag_1'],
      note6: json['note_flag_6'],
      location0: json['location_flag_0'],
      location1: json['location_flag_1'],
      location6: json['location_flag_6'],
      fullName: json['full_name'] ?? json['nama'] ?? '',
      isApprove0: isClockIn ? isApproveInt : null,
      isApprove1: !isClockIn ? isApproveInt : null,
      isReject0: isClockIn ? isRejectInt : null,
      isReject1: !isClockIn ? isRejectInt : null,
      needsApproval0: isClockIn ? needsApprovalBool : null,
      needsApproval1: !isClockIn ? needsApprovalBool : null,
      approveName0: isClockIn ? approveName : null,
      approveName1: !isClockIn ? approveName : null,
      rejectName0: isClockIn ? rejectName : null,
      rejectName1: !isClockIn ? rejectName : null,
    );
  }

}