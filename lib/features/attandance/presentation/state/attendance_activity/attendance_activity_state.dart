import 'package:progress_group/features/attandance/domain/entities/attendance_activity_entity.dart';

abstract class AttendanceActivityState {}

class AttendanceActivityInitial extends AttendanceActivityState {}

class AttendanceActivityLoading extends AttendanceActivityState {}

class AttendanceActivityLoaded extends AttendanceActivityState {
  final List<AttendanceActivityEntity> activityLogs;
  final int activityPage;
  final int activityLastPage;
  final bool activityLoadingMore;

  AttendanceActivityLoaded({
    this.activityLogs = const [],
    this.activityPage = 1,
    this.activityLastPage = 1,
    this.activityLoadingMore = false,
  });
}

class AttendanceActivityError extends AttendanceActivityState {
  final String message;
  AttendanceActivityError(this.message);
}
