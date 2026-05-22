import 'package:progress_group/features/attandance/domain/entities/attendance_activity_entity.dart';
import 'package:progress_group/features/attandance/domain/repositories/attandance_repository.dart';

class GetAttendanceActivityUseCase {
  final AttendanceRepository repository;
  GetAttendanceActivityUseCase(this.repository);

  Future<({List<AttendanceActivityEntity> data, int lastPage})> call({
    List<int>? salesPersonIds,
    String? startDate,
    String? endDate,
    String? location,
    int page = 1,
    int perPage = 20,
  }) {
    return repository.getAttendanceActivity(
      salesPersonIds: salesPersonIds,
      startDate: startDate,
      endDate: endDate,
      location: location,
      page: page,
      perPage: perPage,
    );
  }
}
