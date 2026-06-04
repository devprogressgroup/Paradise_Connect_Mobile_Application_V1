import 'package:flutter/foundation.dart';
import '../../../domain/entities/attendance_approval_entity.dart';

@immutable
abstract class AttendanceApprovalState {}

class AttendanceApprovalInitial extends AttendanceApprovalState {}

class AttendanceApprovalLoading extends AttendanceApprovalState {}

class AttendanceApprovalLoaded extends AttendanceApprovalState {
  final List<AttendanceApprovalEntity> logs;
  final int page;
  final int lastPage;
  final String? search;
  final String? status;
  final int? flag;
  final bool isLoadingMore;

  AttendanceApprovalLoaded({
    required this.logs,
    required this.page,
    required this.lastPage,
    this.search,
    this.status,
    this.flag,
    this.isLoadingMore = false,
  });

  AttendanceApprovalLoaded copyWith({
    List<AttendanceApprovalEntity>? logs,
    int? page,
    int? lastPage,
    String? search,
    String? status,
    int? flag,
    bool? isLoadingMore,
  }) {
    return AttendanceApprovalLoaded(
      logs: logs ?? this.logs,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      search: search ?? this.search,
      status: status ?? this.status,
      flag: flag ?? this.flag,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class AttendanceApprovalError extends AttendanceApprovalState {
  final String message;

  AttendanceApprovalError(this.message);
}
