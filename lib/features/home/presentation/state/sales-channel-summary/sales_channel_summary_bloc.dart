import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/home/domain/usecases/get_sales_channels_summary_usecase.dart';
import 'sales_channel_summary_event.dart';
import 'sales_channel_summary_state.dart';

class SalesChannelSummaryBloc extends Bloc<SalesChannelSummaryEvent, SalesChannelSummaryState> {
  final GetSalesChannelsSummaryUseCase getSalesChannelsSummaryUseCase;

  SalesChannelSummaryBloc({required this.getSalesChannelsSummaryUseCase})
      : super(const SalesChannelSummaryState()) {
    on<FetchSalesChannelsSummaryEvent>(_onFetch, transformer: restartable());
  }

  Future<void> _onFetch(
    FetchSalesChannelsSummaryEvent event,
    Emitter<SalesChannelSummaryState> emit,
  ) async {
    emit(state.copyWith(status: SalesChannelSummaryStatus.loading));
    try {
      final summary = await getSalesChannelsSummaryUseCase(startDate: event.startDate, endDate: event.endDate);
      emit(state.copyWith(status: SalesChannelSummaryStatus.loaded, summary: summary));
    } catch (e) {
      emit(state.copyWith(status: SalesChannelSummaryStatus.error, errorMessage: e.toString()));
    }
  }
}
