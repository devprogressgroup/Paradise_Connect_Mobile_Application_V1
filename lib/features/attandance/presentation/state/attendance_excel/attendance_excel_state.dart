import 'dart:typed_data';

abstract class AttendanceExcelState {}

class AttendanceExcelInitial extends AttendanceExcelState {}

class AttendanceExcelLoading extends AttendanceExcelState {}

class AttendanceExcelSuccess extends AttendanceExcelState {
  final String filePath;
  AttendanceExcelSuccess(this.filePath);
}

class AttendanceExcelWebSuccess extends AttendanceExcelState {
  final Uint8List bytes;
  final String fileName;
  AttendanceExcelWebSuccess(this.bytes, this.fileName);
}

class AttendanceExcelError extends AttendanceExcelState {
  final String message;
  AttendanceExcelError(this.message);
}
