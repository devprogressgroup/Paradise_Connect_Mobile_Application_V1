import '../../../domain/entities/user_profile.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfileEntity profile;
  ProfileLoaded(this.profile);
}

class ProfileFailure extends ProfileState {
  final String message;
  ProfileFailure(this.message);
}
