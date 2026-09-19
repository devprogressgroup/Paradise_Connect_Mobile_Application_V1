import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/get_reserve_statuses_usecase.dart';
import 'reserve_status_event.dart';
import 'reserve_status_state.dart';

class ReserveStatusBloc extends Bloc<ReserveStatusEvent, ReserveStatusState> {
  final GetReserveStatusesUseCase getReserveStatusesUseCase;

  ReserveStatusBloc({required this.getReserveStatusesUseCase}) : super(const ReserveStatusState()) {
    on<FetchReserveStatusesEvent>(_onFetch);
  }

  Future<void> _onFetch(
    FetchReserveStatusesEvent event,
    Emitter<ReserveStatusState> emit,
  ) async {
    emit(state.copyWith(status: ReserveStatusEnum.loading));

    final result = await getReserveStatusesUseCase();

    result.fold(
      (failure) => emit(state.copyWith(status: ReserveStatusEnum.error, errorMessage: failure)),
      (data) => emit(state.copyWith(status: ReserveStatusEnum.loaded, statuses: data)),
    );
  }
}
