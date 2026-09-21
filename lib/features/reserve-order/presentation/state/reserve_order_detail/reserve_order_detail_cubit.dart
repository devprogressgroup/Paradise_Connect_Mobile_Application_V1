import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/reserve-order/domain/entities/edit_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/topup_reserve_order_params.dart';
import 'package:progress_group/features/reserve-order/domain/entities/update_reserve_order_customer_params.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/delete_reserve_order_usecase.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/edit_reserve_order_usecase.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/get_reserve_order_detail_usecase.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/send_reserve_order_message_usecase.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/topup_reserve_order_usecase.dart';
import 'package:progress_group/features/reserve-order/domain/usecases/update_reserve_order_customer_usecase.dart';
import 'reserve_order_detail_state.dart';

/// State detail 1 Reserve Order — juga menangani "Perbaiki Data Customer" (`update`) & "Top Up
/// Pembayaran" (`topup`), yang keduanya balik detail TERBARU dari server (dipakai langsung
/// menggantikan [ReserveOrderDetailState.detail], tanpa perlu fetch ulang).
class ReserveOrderDetailCubit extends Cubit<ReserveOrderDetailState> {
  final GetReserveOrderDetailUseCase getReserveOrderDetailUseCase;
  final UpdateReserveOrderCustomerUseCase updateReserveOrderCustomerUseCase;
  final TopupReserveOrderUseCase topupReserveOrderUseCase;
  final SendReserveOrderMessageUseCase sendReserveOrderMessageUseCase;
  final EditReserveOrderUseCase editReserveOrderUseCase;
  final DeleteReserveOrderUseCase deleteReserveOrderUseCase;

  ReserveOrderDetailCubit({
    required this.getReserveOrderDetailUseCase,
    required this.updateReserveOrderCustomerUseCase,
    required this.topupReserveOrderUseCase,
    required this.sendReserveOrderMessageUseCase,
    required this.editReserveOrderUseCase,
    required this.deleteReserveOrderUseCase,
  }) : super(const ReserveOrderDetailState());

  Future<void> fetch(int reserveOrderId) async {
    emit(state.copyWith(status: ReserveOrderDetailStatus.loading));

    final result = await getReserveOrderDetailUseCase(reserveOrderId);

    result.fold(
      (message) => emit(
        state.copyWith(
          status: ReserveOrderDetailStatus.error,
          errorMessage: message,
        ),
      ),
      (data) => emit(
        state.copyWith(status: ReserveOrderDetailStatus.loaded, detail: data),
      ),
    );
  }

  Future<String?> updateCustomer(
    int reserveOrderId,
    UpdateReserveOrderCustomerParams params,
  ) async {
    emit(state.copyWith(status: ReserveOrderDetailStatus.mutating));

    final result = await updateReserveOrderCustomerUseCase(
      reserveOrderId,
      params,
    );

    return result.fold(
      (message) {
        emit(
          state.copyWith(
            status: ReserveOrderDetailStatus.loaded,
            errorMessage: message,
          ),
        );
        return message;
      },
      (data) {
        emit(
          state.copyWith(status: ReserveOrderDetailStatus.loaded, detail: data),
        );
        return null;
      },
    );
  }

  Future<String?> topup(
    int reserveOrderId,
    TopupReserveOrderParams params,
  ) async {
    emit(state.copyWith(status: ReserveOrderDetailStatus.mutating));

    final result = await topupReserveOrderUseCase(reserveOrderId, params);

    return result.fold(
      (message) {
        emit(
          state.copyWith(
            status: ReserveOrderDetailStatus.loaded,
            errorMessage: message,
          ),
        );
        return message;
      },
      (data) {
        emit(
          state.copyWith(status: ReserveOrderDetailStatus.loaded, detail: data),
        );
        return null;
      },
    );
  }

  Future<String?> sendMessage(int reserveOrderId, String message) async {
    emit(state.copyWith(status: ReserveOrderDetailStatus.mutating));

    final result = await sendReserveOrderMessageUseCase(
      reserveOrderId,
      message,
    );

    return result.fold(
      (errorMessage) {
        emit(
          state.copyWith(
            status: ReserveOrderDetailStatus.loaded,
            errorMessage: errorMessage,
          ),
        );
        return errorMessage;
      },
      (data) {
        emit(
          state.copyWith(status: ReserveOrderDetailStatus.loaded, detail: data),
        );
        return null;
      },
    );
  }

  Future<String?> editOrder(
    int reserveOrderId,
    EditReserveOrderParams params,
  ) async {
    emit(state.copyWith(status: ReserveOrderDetailStatus.mutating));

    final result = await editReserveOrderUseCase(reserveOrderId, params);

    return result.fold(
      (message) {
        emit(
          state.copyWith(
            status: ReserveOrderDetailStatus.loaded,
            errorMessage: message,
          ),
        );
        return message;
      },
      (data) {
        emit(
          state.copyWith(status: ReserveOrderDetailStatus.loaded, detail: data),
        );
        return null;
      },
    );
  }

  /// Hapus PERMANEN — tidak ada state "detail" lagi setelah ini berhasil, jadi halaman pemanggil
  /// wajib langsung keluar (pop) begitu balikannya `null` (sukses), bukan menunggu rebuild.
  Future<String?> delete(int reserveOrderId) async {
    emit(state.copyWith(status: ReserveOrderDetailStatus.mutating));

    final result = await deleteReserveOrderUseCase(reserveOrderId);

    return result.fold((message) {
      emit(
        state.copyWith(
          status: ReserveOrderDetailStatus.loaded,
          errorMessage: message,
        ),
      );
      return message;
    }, (_) => null);
  }
}
