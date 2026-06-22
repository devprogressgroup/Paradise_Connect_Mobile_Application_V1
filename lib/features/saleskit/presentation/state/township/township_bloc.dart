import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/saleskit/domain/usecase/get_townships_saleskit_usecase.dart';
import 'package:progress_group/features/saleskit/domain/usecase/get_townships_usecase.dart';
import 'township_event.dart';
import 'township_state.dart';

class TownshipBloc extends Bloc<TownshipEvent, TownshipState> {
  final GetTownshipsUseCase getTownshipsUseCase;
  final GetTownshipsSalesKitUseCase getTownshipsSalesKitUseCase;

  TownshipBloc(this.getTownshipsUseCase, this.getTownshipsSalesKitUseCase) : super(TownshipInitial()) {
    on<GetTownshipsEvent>((event, emit) async {
      emit(TownshipLoading());
      try {
        final townships = await getTownshipsUseCase();
        emit(TownshipLoaded(townships));
      } catch (e) {
        emit(TownshipError(cleanErrorMessage(e)));
      }
    });

    on<GetTownshipsSalesKitEvent>((event, emit) async {
      emit(TownshipLoading());
      try {
        final townships = await getTownshipsSalesKitUseCase();
        emit(TownshipLoaded(townships));
      } catch (e) {
        emit(TownshipError(cleanErrorMessage(e)));
      }
    });
  }
}
