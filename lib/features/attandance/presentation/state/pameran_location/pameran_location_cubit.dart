import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/attandance/domain/entities/location_entity.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_locations.dart';

class PameranLocationCubit extends Cubit<List<AttendanceLocation>> {
  final GetLocationsUseCase getLocationsUseCase;

  PameranLocationCubit(this.getLocationsUseCase) : super([]);

  Future<void> load() async {
    try {
      final locations = await getLocationsUseCase();
      emit(locations);
    } catch (_) {}
  }
}
