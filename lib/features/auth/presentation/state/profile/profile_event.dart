abstract class ProfileEvent {}

class GetProfileEvent extends ProfileEvent {
  final bool forceRefresh;
  /// silent = refresh di latar belakang tanpa state Loading/Failure (anti-flicker).
  final bool silent;
  GetProfileEvent({this.forceRefresh = false, this.silent = false});
}

class ClearProfileEvent extends ProfileEvent {}
