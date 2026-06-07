import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/attandance/domain/entities/location_entity.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_office_locations.dart';

class OfficeLocationCubit extends Cubit<List<AttendanceLocation>> {
  final GetOfficeLocationsUseCase getOfficeLocationsUseCase;

  OfficeLocationCubit(this.getOfficeLocationsUseCase) : super([]);

  Future<void> load({bool force = false}) async {
    if (!force && state.isNotEmpty) return;
    try {
      final locations = await getOfficeLocationsUseCase();
      emit(locations);
    } catch (e) {
      // ignore
    }
  }
}
