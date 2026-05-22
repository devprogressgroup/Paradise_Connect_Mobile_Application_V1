import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/contact/data/arguments/contact_dropdown_args.dart';
import 'package:progress_group/features/contact/domain/usecases/property/get_property_commercial_units_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/property/get_property_units_usecase.dart';
import 'property_unit_state.dart';

class PropertyUnitCubit extends Cubit<PropertyUnitState> {
  final GetPropertyUnitsUseCase getPropertyUnitsUseCase;
  final GetPropertyCommercialUnitsUseCase getPropertyCommercialUnitsUseCase;

  PropertyUnitCubit(this.getPropertyUnitsUseCase, this.getPropertyCommercialUnitsUseCase)
      : super(PropertyUnitInitial());

  void reset() => emit(PropertyUnitInitial());

  Future<void> load(int townshipId, {bool isCommercial = false}) async {
    emit(PropertyUnitLoading());

    final result = isCommercial
        ? await getPropertyCommercialUnitsUseCase(townshipId: townshipId)
        : await getPropertyUnitsUseCase(townshipId: townshipId);

    result.fold(
      (failure) => emit(PropertyUnitError(failure)),
      (clusters) {
        final items = clusters
            .expand((cluster) => cluster.units.map(
                  (unit) => OwnerDropdownItem(
                    id: unit.id,
                    name: '${cluster.clusterName} - ${unit.name}',
                    typeData: cluster.clusterId.toString(),
                  ),
                ))
            .toList();
        emit(PropertyUnitLoaded(items));
      },
    );
  }
}
