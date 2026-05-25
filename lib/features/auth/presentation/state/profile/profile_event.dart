abstract class ProfileEvent {}

class GetProfileEvent extends ProfileEvent {
  final bool forceRefresh;
  GetProfileEvent({this.forceRefresh = false});
}

class ClearProfileEvent extends ProfileEvent {}
