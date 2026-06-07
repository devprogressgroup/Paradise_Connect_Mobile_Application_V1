import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import '../../../domain/repositories/attandance_repository.dart';
import 'attendance_pdf_state.dart';

class AttendancePdfCubit extends Cubit<AttendancePdfState> {
  final AttendanceRepository repository;

  AttendancePdfCubit(this.repository) : super(AttendancePdfInitial());

  Future<void> download({
    int? nikNumber,
    int? salesPersonId,
    required String startDate,
    required String endDate,
  }) async {
    emit(AttendancePdfLoading());
    final id = salesPersonId ?? nikNumber;
    final fileName = 'kehadiran_${id}_${startDate}_sd_$endDate.pdf';
    try {
      if (kIsWeb) {
        final bytes = await repository.downloadAttendancePdfBytes(
          nikNumber: nikNumber,
          salesPersonId: salesPersonId,
          startDate: startDate,
          endDate: endDate,
        );
        emit(AttendancePdfWebSuccess(bytes, fileName));
      } else {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        await repository.downloadAttendancePdf(
          nikNumber: nikNumber,
          salesPersonId: salesPersonId,
          startDate: startDate,
          endDate: endDate,
          savePath: filePath,
        );
        emit(AttendancePdfSuccess(filePath));
      }
    } catch (e) {
      emit(AttendancePdfError(e.toString()));
    }
  }

  void reset() => emit(AttendancePdfInitial());
}
