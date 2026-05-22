import 'package:progress_group/features/attandance/domain/entities/attandance_entity.dart';
import 'package:progress_group/features/attandance/domain/repositories/attandance_repository.dart';

class GetAttendanceUseCase {
  final AttendanceRepository repository;

  GetAttendanceUseCase(this.repository);

  Future<({List<AttendanceEntity> data, int lastPage})> call({List<int>? salesPersonIds, String? startDate, String? endDate, int page = 1}) {
    return repository.getAttendance(salesPersonIds: salesPersonIds, startDate: startDate, endDate: endDate, page: page);
  }
}