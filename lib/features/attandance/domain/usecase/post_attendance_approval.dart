import '../repositories/attandance_repository.dart';

class PostAttendanceApprovalUseCase {
  final AttendanceRepository repository;

  PostAttendanceApprovalUseCase(this.repository);

  Future<void> call({required int logId, required int approve}) async {
    return await repository.postAttendanceApproval(logId: logId, approve: approve);
  }
}
