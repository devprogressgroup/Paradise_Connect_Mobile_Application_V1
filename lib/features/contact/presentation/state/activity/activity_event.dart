import 'package:equatable/equatable.dart';
import 'package:progress_group/features/contact/domain/entities/activity/create_activity_visit_params.dart';
import '../../../domain/entities/activity/create_activity_params.dart';

abstract class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object?> get props => [];
}

class FetchActivitiesEvent extends ActivityEvent {
  final int? contactId;
  final int? dealId;
  final String? activityType;
  final String? followUpStartDate;
  final String? followUpEndDate;
  final bool isRefresh;

  const FetchActivitiesEvent({
    this.contactId,
    this.dealId,
    this.activityType,
    this.followUpStartDate,
    this.followUpEndDate,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [contactId, dealId, activityType, followUpStartDate, followUpEndDate, isRefresh];
}

class CreateActivityEvent extends ActivityEvent {
  final CreateActivityParams params;

  const CreateActivityEvent(this.params);

  @override
  List<Object?> get props => [params];
}

class CreateVisitEvent {
  final CreateVisitParams params;

  CreateVisitEvent(this.params);
}

class PostStatusFollowEvent extends ActivityEvent {
  final List<int> activityIds;

  const PostStatusFollowEvent(this.activityIds);

  @override
  List<Object?> get props => [activityIds];
}

class ResetActivityEvent extends ActivityEvent {}

class MarkActivitiesAsSeenEvent extends ActivityEvent {
  final List<int> activityIds;
  const MarkActivitiesAsSeenEvent(this.activityIds);

  @override
  List<Object?> get props => [activityIds];
}

class LoadSeenActivitiesEvent extends ActivityEvent {}

abstract class ActivityProspectStatusEvent {}

class FetchActivityProspectStatusEvent extends ActivityProspectStatusEvent {
  final int contactId;

  FetchActivityProspectStatusEvent(this.contactId);
}

class ResetActivityProspectStatusEvent extends ActivityProspectStatusEvent {}