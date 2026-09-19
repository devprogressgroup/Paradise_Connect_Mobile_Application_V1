import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/get_payment_types_usecase.dart';
import 'payment_type_event.dart';
import 'payment_type_state.dart';

class PaymentTypeBloc extends Bloc<PaymentTypeEvent, PaymentTypeState> {
  final GetPaymentTypesUseCase getPaymentTypesUseCase;

  PaymentTypeBloc({required this.getPaymentTypesUseCase})
    : super(const PaymentTypeState()) {
    on<FetchPaymentTypesEvent>(_onFetch);
  }

  Future<void> _onFetch(
    FetchPaymentTypesEvent event,
    Emitter<PaymentTypeState> emit,
  ) async {
    emit(state.copyWith(status: PaymentTypeStatus.loading));

    final result = await getPaymentTypesUseCase();

    result.fold(
      (failure) => emit(
        state.copyWith(status: PaymentTypeStatus.error, errorMessage: failure),
      ),
      (data) =>
          emit(state.copyWith(status: PaymentTypeStatus.loaded, items: data)),
    );
  }
}
