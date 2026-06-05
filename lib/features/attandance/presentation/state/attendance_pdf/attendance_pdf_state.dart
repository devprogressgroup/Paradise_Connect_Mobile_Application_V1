abstract class AttendancePdfState {}

class AttendancePdfInitial extends AttendancePdfState {}

class AttendancePdfLoading extends AttendancePdfState {}

class AttendancePdfSuccess extends AttendancePdfState {
  final String filePath;
  AttendancePdfSuccess(this.filePath);
}

class AttendancePdfError extends AttendancePdfState {
  final String message;
  AttendancePdfError(this.message);
}
