import 'dart:typed_data';
import 'package:progress_group/features/attandance/domain/repositories/attandance_repository.dart';

class SubmitAttendanceUseCase {
  final AttendanceRepository repository;

  SubmitAttendanceUseCase(this.repository);

  Future<void> call({
    required String datetime,
    required int flag,
    required String location,
    String? note,
    String? filePath,
    Uint8List? fileBytes,
    int? locationId,
    String? latitude,
    String? longitude,
  }) {
    return repository.submitAttendance(
      datetime: datetime,
      flag: flag,
      location: location,
      note: note,
      filePath: filePath,
      fileBytes: fileBytes,
      locationId: locationId,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
