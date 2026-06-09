import 'package:equatable/equatable.dart';

class AttendanceApprovalEntity extends Equatable {
  final int logId;
  final int? nikNumber;
  final String? attendanceDatetime;
  final int? flag;
  final String? flagLabel;
  final String? locationName;
  final String? noteValidasi;
  final List<String>? fileAttachment;
  final String? fullName;
  final int? isApprove;
  final int? approveUserId;
  final String? approveUsername;
  final String? approveName;
  final String? approveDatetime;
  final int? isReject;
  final int? rejectUserId;
  final String? rejectUsername;
  final String? rejectName;
  final String? rejectDatetime;

  const AttendanceApprovalEntity({
    required this.logId,
    this.nikNumber,
    this.attendanceDatetime,
    this.flag,
    this.flagLabel,
    this.locationName,
    this.noteValidasi,
    this.fileAttachment,
    this.fullName,
    this.isApprove,
    this.approveUserId,
    this.approveUsername,
    this.approveName,
    this.approveDatetime,
    this.isReject,
    this.rejectUserId,
    this.rejectUsername,
    this.rejectName,
    this.rejectDatetime,
  });

  @override
  List<Object?> get props => [
        logId,
        nikNumber,
        attendanceDatetime,
        flag,
        flagLabel,
        locationName,
        noteValidasi,
        fileAttachment,
        fullName,
        isApprove,
        approveUserId,
        approveUsername,
        approveName,
        approveDatetime,
        isReject,
        rejectUserId,
        rejectUsername,
        rejectName,
        rejectDatetime,
      ];
}
