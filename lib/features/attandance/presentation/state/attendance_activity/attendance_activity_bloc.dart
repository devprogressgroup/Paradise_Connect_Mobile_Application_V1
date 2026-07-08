import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/features/attandance/domain/entities/attendance_activity_entity.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_attendance_activity.dart';
import 'package:progress_group/features/attandance/domain/usecase/validasi_check_in.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_event.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_state.dart';

class AttendanceActivityBloc extends Bloc<AttendanceActivityEvent, AttendanceActivityState> {
  final GetAttendanceActivityUseCase getAttendanceActivityUseCase;
  final ValidasiCheckInUseCase validasiCheckInUseCase;

  AttendanceActivityBloc({required this.getAttendanceActivityUseCase, required this.validasiCheckInUseCase}) : super(AttendanceActivityInitial()) {
    on<ValidasiCheckInEvent>((event, emit) async {
      if (state is! AttendanceActivityLoaded) return;
      final loaded = state as AttendanceActivityLoaded;
      try {
        await validasiCheckInUseCase(logId: event.logId, statusValidasi: event.statusValidasi, noteValidasi: event.noteValidasi);
        final updatedLogs = loaded.activityLogs.map((activity) {
          final updatedCheckIns = activity.checkIns.map((c) {
            if (c.logId == event.logId) {
              return AttendanceActivityCheckIn(
                logId: c.logId,
                checkInDate: c.checkInDate,
                checkInLocation: c.checkInLocation,
                checkInNote: c.checkInNote,
                checkInAttachment: c.checkInAttachment,
                statusValidasi: event.statusValidasi,
                statusValidasiLabel: event.statusValidasi == 1 ? 'Valid' : 'Invalid',
                noteValidasi: event.noteValidasi,
              );
            }
            return c;
          }).toList();
          return AttendanceActivityEntity(
            date: activity.date,
            salesPersonId: activity.salesPersonId,
            fullName: activity.fullName,
            clockInDate: activity.clockInDate,
            clockInLocation: activity.clockInLocation,
            clockInNote: activity.clockInNote,
            clockInAttachment: activity.clockInAttachment,
            clockOutDate: activity.clockOutDate,
            clockOutLocation: activity.clockOutLocation,
            clockOutNote: activity.clockOutNote,
            clockOutAttachment: activity.clockOutAttachment,
            checkIns: updatedCheckIns,
            visits: activity.visits,
          );
        }).toList();
        emit(AttendanceActivityLoaded(
          activityLogs: updatedLogs,
          activityPage: loaded.activityPage,
          activityLastPage: loaded.activityLastPage,
          activityLoadingMore: false,
        ));
      } catch (_) {}
    });

    on<GetAttendanceActivityEvent>((event, emit) async {
      final currentState = state;

      if (!event.isLoadMore) {
        emit(AttendanceActivityLoading());
      } else if (currentState is AttendanceActivityLoaded) {
        emit(AttendanceActivityLoaded(
          activityLogs: currentState.activityLogs,
          activityPage: currentState.activityPage,
          activityLastPage: currentState.activityLastPage,
          activityLoadingMore: true,
        ));
      }

      try {
        final result = await getAttendanceActivityUseCase(
          salesPersonIds: event.salesPersonIds,
          startDate: event.startDate,
          endDate: event.endDate,
          location: event.location,
          page: event.page,
          perPage: event.perPage,
        );

        final List<AttendanceActivityEntity> existingLogs =
            (event.isLoadMore && currentState is AttendanceActivityLoaded)
                ? currentState.activityLogs
                : [];

       
       
       
       
       
        final newPage = [...result.data]..sort((a, b) {
          final dateCompare = b.date.compareTo(a.date);
          if (dateCompare != 0) return dateCompare;
          return _latestActivityTime(b).compareTo(_latestActivityTime(a));
        });

        emit(AttendanceActivityLoaded(
          activityLogs: [...existingLogs, ...newPage],
          activityPage: event.page,
          activityLastPage: result.lastPage,
          activityLoadingMore: false,
        ));
      } catch (e) {
        emit(AttendanceActivityError(cleanErrorMessage(e)));
      }
    });
  }
}

String _latestActivityTime(AttendanceActivityEntity item) {
  final times = <String>[
    if (item.clockInDate != null) item.clockInDate!,
    if (item.clockOutDate != null) item.clockOutDate!,
    for (final c in item.checkIns)
      if (c.checkInDate != null) c.checkInDate!,
    for (final v in item.visits)
      if (v.datetime != null) v.datetime!,
  ];
  if (times.isEmpty) return '';
  return times.reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
}
