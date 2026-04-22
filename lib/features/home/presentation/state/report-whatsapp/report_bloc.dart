import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/home/presentation/state/report-whatsapp/report_event.dart';
import 'package:progress_group/features/home/presentation/state/report-whatsapp/report_state.dart';

import '../../../domain/usecases/get_report_whatsapp_usecase.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final GetVolumeReportUseCase getVolumeReport;

  ReportBloc(this.getVolumeReport) : super(ReportInitial()) {
    on<GetVolumeReportEvent>((event, emit) async {
      emit(ReportLoading());
      try {
        final result = await getVolumeReport(
          event.startDate,
          event.endDate,
          event.groupBy,
        );
        emit(ReportLoaded(result));
      } catch (e) {
        emit(ReportError(e.toString()));
      }
    });
  }
}