import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecase/get_attendance_approval_today.dart';
import '../../../domain/usecase/post_attendance_approval.dart';
import 'attendance_approval_state.dart';

class AttendanceApprovalCubit extends Cubit<AttendanceApprovalState> {
  final GetAttendanceApprovalTodayUseCase getAttendanceApprovalTodayUseCase;
  final PostAttendanceApprovalUseCase postAttendanceApprovalUseCase;

  final ValueNotifier<bool> hasPendingApproval = ValueNotifier(false);

  AttendanceApprovalCubit(
    this.getAttendanceApprovalTodayUseCase,
    this.postAttendanceApprovalUseCase,
  ) : super(AttendanceApprovalInitial());

  Future<void> loadBadge() async {
    try {
      final result = await getAttendanceApprovalTodayUseCase(
        status: 'pending',
        page: 1,
        perPage: 1,
      );
      hasPendingApproval.value = result.data.isNotEmpty;
    } catch (_) {}
  }

  Future<void> load({String? search, String? status, int? flag}) async {
    emit(AttendanceApprovalLoading());
    try {
      final result = await getAttendanceApprovalTodayUseCase(
        search: search,
        status: status,
        flag: flag,
        page: 1,
      );
      emit(AttendanceApprovalLoaded(
        logs: result.data,
        page: 1,
        lastPage: result.lastPage,
        search: search,
        status: status,
        flag: flag,
      ));
    } catch (e) {
      emit(AttendanceApprovalError(e.toString()));
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is AttendanceApprovalLoaded && !currentState.isLoadingMore && currentState.page < currentState.lastPage) {
      emit(currentState.copyWith(isLoadingMore: true));
      try {
        final nextPage = currentState.page + 1;
        final result = await getAttendanceApprovalTodayUseCase(
          search: currentState.search,
          status: currentState.status,
          flag: currentState.flag,
          page: nextPage,
        );
        emit(currentState.copyWith(
          logs: [...currentState.logs, ...result.data],
          page: nextPage,
          lastPage: result.lastPage,
          isLoadingMore: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> submitApproval(int logId, int approve) async {
    final currentState = state;
    String? search, status;
    int? flag;
    if (currentState is AttendanceApprovalLoaded) {
      search = currentState.search;
      status = currentState.status;
      flag = currentState.flag;
    }
    emit(AttendanceApprovalLoading());
    try {
      await postAttendanceApprovalUseCase(logId: logId, approve: approve);
      await load(search: search, status: status, flag: flag);
      await loadBadge();
    } catch (e) {
      if (currentState is AttendanceApprovalLoaded) {
        emit(AttendanceApprovalLoaded(
          logs: currentState.logs,
          page: currentState.page,
          lastPage: currentState.lastPage,
          search: currentState.search,
          status: currentState.status,
          flag: currentState.flag,
        ));
      } else {
        emit(AttendanceApprovalError(e.toString()));
      }
      throw Exception(e.toString());
    }
  }
}
