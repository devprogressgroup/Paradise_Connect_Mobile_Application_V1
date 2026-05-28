import 'dart:typed_data';
import 'package:progress_group/features/attandance/domain/repositories/attandance_repository.dart';

class SubmitAttendanceActivityUseCase {
  final AttendanceRepository repository;

  SubmitAttendanceActivityUseCase(this.repository);

  Future<void> call({
    required String datetime,
    required int flag,
    required String location,
    String? note,
    required List<String> filePaths,
    List<Uint8List>? fileBytesData,
    required int nikNumber,
  }) {
    return repository.submitAttendanceActivity(
      datetime: datetime,
      flag: flag,
      location: location,
      note: note,
      filePaths: filePaths,
      fileBytesData: fileBytesData,
      nikNumber: nikNumber,
    );
  }
}
