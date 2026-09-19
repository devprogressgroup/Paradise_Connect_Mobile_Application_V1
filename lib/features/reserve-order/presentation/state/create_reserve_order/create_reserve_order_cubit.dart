import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/reserve-order/domain/entities/create_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/create_reserve_order_usecase.dart';
import 'create_reserve_order_state.dart';

class CreateReserveOrderCubit extends Cubit<CreateReserveOrderState> {
  final CreateReserveOrderUseCase createReserveOrderUseCase;

  CreateReserveOrderCubit(this.createReserveOrderUseCase)
      : super(const CreateReserveOrderInitial());

  Future<void> submit(CreateReserveOrderParams params) async {
    emit(const CreateReserveOrderSubmitting());
    final result = await createReserveOrderUseCase(params);
    result.fold(
      (message) => emit(CreateReserveOrderError(message)),
      (data) => emit(CreateReserveOrderSuccess(data)),
    );
  }

  void reset() => emit(const CreateReserveOrderInitial());
}
