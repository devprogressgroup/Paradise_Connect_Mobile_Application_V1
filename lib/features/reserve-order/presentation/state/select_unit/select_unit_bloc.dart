import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/get_select_unit_usecase.dart';
import 'select_unit_event.dart';
import 'select_unit_state.dart';

class SelectUnitBloc extends Bloc<SelectUnitEvent, SelectUnitState> {
  final GetSelectUnitUseCase getSelectUnitUseCase;

  SelectUnitBloc({required this.getSelectUnitUseCase})
    : super(const SelectUnitState()) {
    on<FetchSelectUnitEvent>(_onFetch);
    on<ResetSelectUnitEvent>((event, emit) => emit(const SelectUnitState()));
  }

  Future<void> _onFetch(
    FetchSelectUnitEvent event,
    Emitter<SelectUnitState> emit,
  ) async {
    emit(state.copyWith(status: SelectUnitStatus.loading));

    final result = await getSelectUnitUseCase(
      contactId: event.contactId,
      townshipId: event.townshipId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(status: SelectUnitStatus.error, errorMessage: failure),
      ),
      (data) =>
          emit(state.copyWith(status: SelectUnitStatus.loaded, items: data)),
    );
  }
}
