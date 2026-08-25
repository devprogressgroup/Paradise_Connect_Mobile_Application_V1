import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/attandance/domain/entities/location_entity.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_all_office_locations.dart';

class AllOfficeLocationCubit extends Cubit<List<AttendanceLocation>> {
  final GetAllOfficeLocationsUseCase getAllOfficeLocationsUseCase;

  AllOfficeLocationCubit(this.getAllOfficeLocationsUseCase) : super([]);

  Future<void> load({bool force = false}) async {
    if (!force && state.isNotEmpty) return;
    try {
      final locations = await getAllOfficeLocationsUseCase();
      emit(locations);
    } catch (e) {

    }
  }
}
