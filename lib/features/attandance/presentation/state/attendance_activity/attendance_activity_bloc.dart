import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/attandance/domain/entities/attendance_activity_entity.dart';
import 'package:progress_group/features/attandance/domain/usecase/get_attendance_activity.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_event.dart';
import 'package:progress_group/features/attandance/presentation/state/attendance_activity/attendance_activity_state.dart';

class AttendanceActivityBloc extends Bloc<AttendanceActivityEvent, AttendanceActivityState> {
  final GetAttendanceActivityUseCase getAttendanceActivityUseCase;

  AttendanceActivityBloc({required this.getAttendanceActivityUseCase}) : super(AttendanceActivityInitial()) {
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
        );

        final List<AttendanceActivityEntity> existingLogs =
            (event.isLoadMore && currentState is AttendanceActivityLoaded)
                ? currentState.activityLogs
                : [];

        emit(AttendanceActivityLoaded(
          activityLogs: [...existingLogs, ...result.data],
          activityPage: event.page,
          activityLastPage: result.lastPage,
          activityLoadingMore: false,
        ));
      } catch (e) {
        emit(AttendanceActivityError(e.toString()));
      }
    });
  }
}
