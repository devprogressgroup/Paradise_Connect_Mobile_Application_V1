abstract class ProfileEvent {}

class GetProfileEvent extends ProfileEvent {
  final bool forceRefresh;
  final bool silent;
  GetProfileEvent({this.forceRefresh = false, this.silent = false});
}

class ClearProfileEvent extends ProfileEvent {}
