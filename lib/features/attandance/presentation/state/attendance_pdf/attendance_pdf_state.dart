import 'dart:typed_data';

abstract class AttendancePdfState {}

class AttendancePdfInitial extends AttendancePdfState {}

class AttendancePdfLoading extends AttendancePdfState {}

class AttendancePdfSuccess extends AttendancePdfState {
  final String filePath;
  AttendancePdfSuccess(this.filePath);
}

class AttendancePdfWebSuccess extends AttendancePdfState {
  final Uint8List bytes;
  final String fileName;
  AttendancePdfWebSuccess(this.bytes, this.fileName);
}

class AttendancePdfError extends AttendancePdfState {
  final String message;
  AttendancePdfError(this.message);
}
