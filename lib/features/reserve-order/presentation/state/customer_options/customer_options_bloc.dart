import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/get_customer_options_usecase.dart';
import 'customer_options_event.dart';
import 'customer_options_state.dart';

/// Opsi dropdown "Data Customer" (GET /reserve-order/customer-options) — dipakai tab Customer
/// detail Reserve Order & halaman Edit Data Customer.
class CustomerOptionsBloc
    extends Bloc<CustomerOptionsEvent, CustomerOptionsState> {
  final GetCustomerOptionsUseCase getCustomerOptionsUseCase;

  CustomerOptionsBloc({required this.getCustomerOptionsUseCase})
    : super(const CustomerOptionsState()) {
    on<FetchCustomerOptionsEvent>(_onFetch);
  }

  Future<void> _onFetch(
    FetchCustomerOptionsEvent event,
    Emitter<CustomerOptionsState> emit,
  ) async {
    // Daftar master (statis) — cukup dimuat sekali per sesi app.
    if (state.status == CustomerOptionsStatus.loaded ||
        state.status == CustomerOptionsStatus.loading) {
      return;
    }
    emit(state.copyWith(status: CustomerOptionsStatus.loading));

    final result = await getCustomerOptionsUseCase();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: CustomerOptionsStatus.error,
          errorMessage: failure,
        ),
      ),
      (data) => emit(
        state.copyWith(status: CustomerOptionsStatus.loaded, options: data),
      ),
    );
  }
}
