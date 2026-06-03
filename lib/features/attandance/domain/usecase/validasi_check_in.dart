import 'package:progress_group/features/attandance/domain/repositories/attandance_repository.dart';

class ValidasiCheckInUseCase {
  final AttendanceRepository repository;

  ValidasiCheckInUseCase(this.repository);

  Future<void> call({required int logId, required int statusValidasi, String? noteValidasi}) {
    return repository.validasiCheckIn(logId: logId, statusValidasi: statusValidasi, noteValidasi: noteValidasi);
  }
}
