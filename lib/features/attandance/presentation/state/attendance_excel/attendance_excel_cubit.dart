import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import '../../../domain/repositories/attandance_repository.dart';
import 'attendance_excel_state.dart';

class AttendanceExcelCubit extends Cubit<AttendanceExcelState> {
  final AttendanceRepository repository;

  AttendanceExcelCubit(this.repository) : super(AttendanceExcelInitial());

  Future<void> download({
    int? nikNumber,
    int? salesPersonId,
    required String startDate,
    required String endDate,
  }) async {
    emit(AttendanceExcelLoading());
    final id = salesPersonId ?? nikNumber;
    final fileName = 'kehadiran_${id}_${startDate}_sd_$endDate.xlsx';
    try {
      if (kIsWeb) {
        final bytes = await repository.downloadAttendanceExcelBytes(
          nikNumber: nikNumber,
          salesPersonId: salesPersonId,
          startDate: startDate,
          endDate: endDate,
        );
        emit(AttendanceExcelWebSuccess(bytes, fileName));
      } else {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/$fileName';
        await repository.downloadAttendanceExcel(
          nikNumber: nikNumber,
          salesPersonId: salesPersonId,
          startDate: startDate,
          endDate: endDate,
          savePath: filePath,
        );
        emit(AttendanceExcelSuccess(filePath));
      }
    } catch (e) {
      emit(AttendanceExcelError(cleanErrorMessage(e)));
    }
  }

  void reset() => emit(AttendanceExcelInitial());
}
