import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/home/domain/usecases/get_prospect_status_summary_usecase.dart';
import 'prospect_status_summary_event.dart';
import 'prospect_status_summary_state.dart';

class ProspectStatusSummaryBloc extends Bloc<ProspectStatusSummaryEvent, ProspectStatusSummaryState> {
  final GetProspectStatusSummaryUseCase getProspectStatusSummaryUseCase;

  ProspectStatusSummaryBloc({required this.getProspectStatusSummaryUseCase})
      : super(const ProspectStatusSummaryState()) {
    
    
    
    
    on<FetchProspectStatusSummaryEvent>(_onFetch, transformer: restartable());
  }

  Future<void> _onFetch(
    FetchProspectStatusSummaryEvent event,
    Emitter<ProspectStatusSummaryState> emit,
  ) async {
    emit(state.copyWith(status: ProspectStatusSummaryStatus.loading));
    try {
      final summary = await getProspectStatusSummaryUseCase(startDate: event.startDate, endDate: event.endDate);
      emit(state.copyWith(status: ProspectStatusSummaryStatus.loaded, summary: summary));
    } catch (e) {
      emit(state.copyWith(status: ProspectStatusSummaryStatus.error, errorMessage: e.toString()));
    }
  }
}
