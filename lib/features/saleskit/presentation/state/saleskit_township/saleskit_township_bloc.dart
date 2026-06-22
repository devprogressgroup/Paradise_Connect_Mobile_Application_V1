import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/saleskit/domain/usecase/get_townships_saleskit_usecase.dart';
import 'saleskit_township_event.dart';
import 'saleskit_township_state.dart';

class SalesKitTownshipBloc extends Bloc<SalesKitTownshipEvent, SalesKitTownshipState> {
  final GetTownshipsSalesKitUseCase getTownshipsSalesKitUseCase;

  SalesKitTownshipBloc(this.getTownshipsSalesKitUseCase) : super(SalesKitTownshipInitial()) {
    on<GetSalesKitTownshipsEvent>((event, emit) async {
      emit(SalesKitTownshipLoading());
      try {
        final townships = await getTownshipsSalesKitUseCase();
        emit(SalesKitTownshipLoaded(townships));
      } catch (e) {
        emit(SalesKitTownshipError(cleanErrorMessage(e)));
      }
    });
  }
}
