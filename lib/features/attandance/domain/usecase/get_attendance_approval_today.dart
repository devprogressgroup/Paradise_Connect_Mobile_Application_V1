import '../entities/attendance_approval_entity.dart';
import '../repositories/attandance_repository.dart';

class GetAttendanceApprovalTodayUseCase {
  final AttendanceRepository repository;

  GetAttendanceApprovalTodayUseCase(this.repository);

  Future<({List<AttendanceApprovalEntity> data, int lastPage})> call({
    String? search,
    String? status,
    int? flag,
    int page = 1,
    int perPage = 10,
  }) async {
    return await repository.getAttendanceApprovalToday(
      search: search,
      status: status,
      flag: flag,
      page: page,
      perPage: perPage,
    );
  }
}
