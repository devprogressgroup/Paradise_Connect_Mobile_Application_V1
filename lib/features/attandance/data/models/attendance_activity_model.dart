import 'package:progress_group/features/attandance/domain/entities/attendance_activity_entity.dart';

class AttendanceActivityVisitModel extends AttendanceActivityVisit {
  AttendanceActivityVisitModel({
    super.datetime,
    super.lastProject,
    super.contactName,
    super.note,
    super.attachment,
  });

  factory AttendanceActivityVisitModel.fromJson(Map<String, dynamic> json) {
    return AttendanceActivityVisitModel(
      datetime: json['activity_date'],
      lastProject: json['last_project'],
      contactName: json['contact_name'],
      note: json['note'],
      attachment: json['image_paths'] != null
          ? List<String>.from(json['image_paths'])
          : null,
    );
  }
}

class AttendanceActivityCheckInModel extends AttendanceActivityCheckIn {
  AttendanceActivityCheckInModel({
    super.logId,
    super.checkInDate,
    super.checkInLocation,
    super.checkInNote,
    super.checkInAttachment,
    super.statusValidasi,
    super.statusValidasiLabel,
    super.noteValidasi,
  });

  factory AttendanceActivityCheckInModel.fromJson(Map<String, dynamic> json) {
    return AttendanceActivityCheckInModel(
      logId: json['log_id'],
      checkInDate: json['check_in_date'],
      checkInLocation: json['check_in_location'],
      checkInNote: json['check_in_note'],
      checkInAttachment: json['check_in_attachment'] != null
          ? List<String>.from(json['check_in_attachment'])
          : null,
      statusValidasi: json['status_validasi'],
      statusValidasiLabel: json['status_validasi_label'],
      noteValidasi: json['note_validasi'],
    );
  }
}

class AttendanceActivityModel extends AttendanceActivityEntity {
  AttendanceActivityModel({
    required super.date,
    required super.salesPersonId,
    required super.fullName,
    super.photoUrl,
    super.clockInDate,
    super.clockInLocation,
    super.clockInNote,
    super.clockInAttachment,
    super.clockOutDate,
    super.clockOutLocation,
    super.clockOutNote,
    super.clockOutAttachment,
    super.checkIns,
    super.visits,
  });

  factory AttendanceActivityModel.fromJson(Map<String, dynamic> json) {
    final visitsList = (json['visits'] as List? ?? []).map((v) => AttendanceActivityVisitModel.fromJson(v as Map<String, dynamic>)).toList();

    final checkInsList = (json['check_ins'] as List? ?? []) .map((c) => AttendanceActivityCheckInModel.fromJson(c as Map<String, dynamic>)) .toList();

    return AttendanceActivityModel(
      date: json['date'] ?? '',
      salesPersonId: json['sales_person_id'] ?? 0,
      fullName: json['full_name'] ?? '',
      photoUrl: json['photo_url'],
      clockInDate: json['clock_in_date'],
      clockInLocation: json['clock_in_location'],
      clockInNote: json['clock_in_note'],
      clockInAttachment: json['clock_in_attachment'] != null? List<String>.from(json['clock_in_attachment']): null,
      clockOutDate: json['clock_out_date'],
      clockOutLocation: json['clock_out_location'],
      clockOutNote: json['clock_out_note'],
      clockOutAttachment: json['clock_out_attachment'] != null
          ? List<String>.from(json['clock_out_attachment'])
          : null,
      checkIns: checkInsList,
      visits: visitsList,
    );
  }
}
