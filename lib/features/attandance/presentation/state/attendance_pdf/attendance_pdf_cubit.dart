import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import '../../../domain/repositories/attandance_repository.dart';
import 'attendance_pdf_state.dart';

class AttendancePdfCubit extends Cubit<AttendancePdfState> {
  final AttendanceRepository repository;

  AttendancePdfCubit(this.repository) : super(AttendancePdfInitial());

  Future<void> download({required int nikNumber, required String startDate, required String endDate}) async {
    emit(AttendancePdfLoading());
    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'kehadiran_${nikNumber}_${startDate}_sd_$endDate.pdf';
      final filePath = '${dir.path}/$fileName';
      await repository.downloadAttendancePdf(
        nikNumber: nikNumber,
        startDate: startDate,
        endDate: endDate,
        savePath: filePath,
      );
      emit(AttendancePdfSuccess(filePath));
    } catch (e) {
      emit(AttendancePdfError(e.toString()));
    }
  }

  void reset() => emit(AttendancePdfInitial());
}
