import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/saleskit/domain/usecase/get_townships_usecase.dart';
import 'township_event.dart';
import 'township_state.dart';

class TownshipBloc extends Bloc<TownshipEvent, TownshipState> {
  final GetTownshipsUseCase getTownshipsUseCase;

  TownshipBloc(this.getTownshipsUseCase) : super(TownshipInitial()) {
    on<GetTownshipsEvent>((event, emit) async {
      emit(TownshipLoading());
      try {
        final townships = await getTownshipsUseCase();
        emit(TownshipLoaded(townships));
      } catch (e) {
        emit(TownshipError(e.toString()));
      }
    });
  }
}
