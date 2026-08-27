import 'package:progress_group/features/attandance/domain/entities/location_entity.dart';
import 'package:progress_group/features/attandance/domain/repositories/attandance_repository.dart';

class GetAllOfficeLocationsUseCase {
  final AttendanceRepository repository;

  GetAllOfficeLocationsUseCase(this.repository);

  Future<List<AttendanceLocation>> call() {
    return repository.getAllOfficeLocations();
  }
}
