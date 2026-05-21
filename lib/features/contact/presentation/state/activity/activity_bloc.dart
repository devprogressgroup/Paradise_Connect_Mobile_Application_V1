import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:progress_group/features/contact/domain/usecases/activity/create_activity_visit_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/activity/get_activity_prospect_status_usecase.dart';
import 'package:progress_group/features/contact/domain/usecases/activity/post_status_follow_usecase.dart';
import '../../../domain/usecases/activity/create_activity_usecase.dart';
import '../../../domain/usecases/activity/get_activities_usecase.dart';
import 'activity_event.dart';
import 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final GetActivitiesUseCase getActivitiesUseCase;
  final CreateActivityUseCase createActivityUseCase;
  final PostStatusFollowUseCase postStatusFollowUseCase;

  ActivityBloc({
    required this.getActivitiesUseCase,
    required this.createActivityUseCase,
    required this.postStatusFollowUseCase,
  }) : super(const ActivityState()) {
    on<FetchActivitiesEvent>(_onFetchActivities);
    on<CreateActivityEvent>(_onCreateActivity);
    on<PostStatusFollowEvent>(_onPostStatusFollow);
    on<ResetActivityEvent>((event, emit) => emit(const ActivityState()));
    on<MarkActivitiesAsSeenEvent>(_onMarkAsSeen);
    on<LoadSeenActivitiesEvent>(_onLoadSeen);
    
    // Auto load when created
    add(LoadSeenActivitiesEvent());
  }

  Future<void> _onFetchActivities(
    FetchActivitiesEvent event,
    Emitter<ActivityState> emit,
  ) async {
    if (event.isRefresh) {
      emit(state.copyWith(
        status: ActivityStatus.loading,
        activities: [],
        currentPage: 1,
        hasReachedMax: false,
      ));
    } else {
      if (state.hasReachedMax) return;
      if (state.status == ActivityStatus.initial) {
        emit(state.copyWith(status: ActivityStatus.loading));
      }
    }

    final result = await getActivitiesUseCase(
      contactId: event.contactId,
      dealId: event.dealId,
      activityType: event.activityType,
      followUpStartDate: event.followUpStartDate,
      followUpEndDate: event.followUpEndDate,
      page: state.currentPage,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ActivityStatus.error,
        errorMessage: failure,
      )),
      (activities) {
        if (activities.isEmpty) {
          emit(state.copyWith(
            status: ActivityStatus.loaded,
            hasReachedMax: true,
          ));
        } else {
          emit(state.copyWith(
            status: ActivityStatus.loaded,
            activities: List.of(state.activities)..addAll(activities),
            currentPage: state.currentPage + 1,
            hasReachedMax: activities.length < 15, // matches per_page
          ));
        }
      },
    );
  }

  Future<void> _onCreateActivity(
    CreateActivityEvent event,
    Emitter<ActivityState> emit,
  ) async {
    emit(state.copyWith(status: ActivityStatus.creating));

    final result = await createActivityUseCase(event.params);

    result.fold(
      (failure) => emit(state.copyWith(
        status: ActivityStatus.error,
        errorMessage: failure,
      )),
      (_) => emit(state.copyWith(status: ActivityStatus.createSuccess)),
    );
  }

  Future<void> _onPostStatusFollow(
    PostStatusFollowEvent event,
    Emitter<ActivityState> emit,
  ) async {
    emit(state.copyWith(status: ActivityStatus.followUpLoading));

    final result = await postStatusFollowUseCase(event.activityIds);

    result.fold(
      (failure) => emit(state.copyWith(status: ActivityStatus.error, errorMessage: failure)),
      (_) {
        final updatedActivities = state.activities
            .where((a) => !event.activityIds.contains(a.activityId))
            .toList();
        emit(state.copyWith(
          status: ActivityStatus.followUpSuccess,
          activities: updatedActivities,
        ));
      },
    );
  }

  Future<void> _onMarkAsSeen(MarkActivitiesAsSeenEvent event, Emitter<ActivityState> emit) async {
    final newSeen = Set<int>.from(state.seenActivityIds)..addAll(event.activityIds);
    emit(state.copyWith(seenActivityIds: newSeen));
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('seen_activity_ids', newSeen.map((id) => id.toString()).toList());
    } catch (e) {
      print("Error saving seen activities: $e");
    }
  }

  Future<void> _onLoadSeen(LoadSeenActivitiesEvent event, Emitter<ActivityState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenList = prefs.getStringList('seen_activity_ids') ?? [];
      final seenSet = seenList.map((id) => int.tryParse(id)).whereType<int>().toSet();
      emit(state.copyWith(seenActivityIds: seenSet));
    } catch (e) {
      print("Error loading seen activities: $e");
    }
  }
}

class NotifActivityBloc extends ActivityBloc {
  NotifActivityBloc({
    required super.getActivitiesUseCase,
    required super.createActivityUseCase,
    required super.postStatusFollowUseCase,
  });
}



class ActivityVisitBloc extends Bloc<CreateVisitEvent, VisitState> {
  final CreateActivityVisitUseCase createVisit;

  ActivityVisitBloc(this.createVisit) : super(VisitInitial()) {
    on<CreateVisitEvent>((event, emit) async {
      emit(VisitLoading());

      final result = await createVisit(event.params);

      result.fold(
        (l) => emit(VisitError(l)),
        (_) => emit(VisitSuccess()),
      );
    });
  }
}


class ActivityProspectStatusBloc extends Bloc<ActivityProspectStatusEvent, ActivityProspectStatusState> {
  final GetActivityProspectStatusUseCase useCase;

  ActivityProspectStatusBloc(this.useCase) : super(const ActivityProspectStatusState()) {
    on<FetchActivityProspectStatusEvent>(_onFetch);
    on<ResetActivityProspectStatusEvent>((event, emit) => emit(const ActivityProspectStatusState()));
  }

  Future<void> _onFetch(
    FetchActivityProspectStatusEvent event,
    Emitter<ActivityProspectStatusState> emit,
  ) async {
    emit(state.copyWith(status: ActivityProspectStatusStatus.loading));

    final result = await useCase(event.contactId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: ActivityProspectStatusStatus.error,
        errorMessage: failure,
      )),
      (data) => emit(state.copyWith(
        status: ActivityProspectStatusStatus.loaded,
        data: data,
      )),
    );
  }
}