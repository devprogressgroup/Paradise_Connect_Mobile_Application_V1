import 'package:equatable/equatable.dart';
import 'package:progress_group/features/contact/domain/entities/activity/activity_entity.dart';
import 'package:progress_group/features/contact/domain/entities/activity/activity_prospect_status.dart';

enum ActivityStatus { initial, loading, loaded, error, creating, createSuccess, followUpLoading, followUpSuccess }

class ActivityState extends Equatable {
  final ActivityStatus status;
  final List<ActivityEntity> activities;
  final String? errorMessage;
  final int currentPage;
  final bool hasReachedMax;
  final Set<int> seenActivityIds;

  const ActivityState({
    this.status = ActivityStatus.initial,
    this.activities = const [],
    this.errorMessage,
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.seenActivityIds = const {},
  });

  ActivityState copyWith({
    ActivityStatus? status,
    List<ActivityEntity>? activities,
    String? errorMessage,
    int? currentPage,
    bool? hasReachedMax,
    Set<int>? seenActivityIds,
  }) {
    return ActivityState(
      status: status ?? this.status,
      activities: activities ?? this.activities,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      seenActivityIds: seenActivityIds ?? this.seenActivityIds,
    );
  }

  @override
  List<Object?> get props => [status, activities, errorMessage, currentPage, hasReachedMax, seenActivityIds];
}


abstract class VisitState {}

class VisitInitial extends VisitState {}
class VisitLoading extends VisitState {}
class VisitSuccess extends VisitState {}
class VisitError extends VisitState {
  final String message;
  VisitError(this.message);
}



enum ActivityProspectStatusStatus { initial, loading, loaded, error }

class ActivityProspectStatusState extends Equatable {
  final ActivityProspectStatusStatus status;
  final List<ActivityProspectStatusEntity> data;
  final String? errorMessage;

  const ActivityProspectStatusState({
    this.status = ActivityProspectStatusStatus.initial,
    this.data = const [],
    this.errorMessage,
  });

  ActivityProspectStatusState copyWith({
    ActivityProspectStatusStatus? status,
    List<ActivityProspectStatusEntity>? data,
    String? errorMessage,
  }) {
    return ActivityProspectStatusState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}