import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/get_cara_bayar_usecase.dart';
import 'cara_bayar_event.dart';
import 'cara_bayar_state.dart';

class CaraBayarBloc extends Bloc<CaraBayarEvent, CaraBayarState> {
  final GetCaraBayarUseCase getCaraBayarUseCase;

  CaraBayarBloc({required this.getCaraBayarUseCase})
    : super(const CaraBayarState()) {
    on<FetchCaraBayarEvent>(_onFetch);
  }

  Future<void> _onFetch(
    FetchCaraBayarEvent event,
    Emitter<CaraBayarState> emit,
  ) async {
    emit(state.copyWith(status: CaraBayarStatus.loading));

    final result = await getCaraBayarUseCase();

    result.fold(
      (failure) => emit(
        state.copyWith(status: CaraBayarStatus.error, errorMessage: failure),
      ),
      (data) =>
          emit(state.copyWith(status: CaraBayarStatus.loaded, items: data)),
    );
  }
}
