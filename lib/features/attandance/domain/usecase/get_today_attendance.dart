import 'package:progress_group/features/attandance/domain/entities/attandance_entity.dart';
import 'package:progress_group/features/attandance/domain/repositories/attandance_repository.dart';

class GetTodayAttendanceUseCase {
  final AttendanceRepository repository;

  GetTodayAttendanceUseCase(this.repository);

  Future<AttendanceEntity?> call() {
    return repository.getTodayAttendance();
  }
}
