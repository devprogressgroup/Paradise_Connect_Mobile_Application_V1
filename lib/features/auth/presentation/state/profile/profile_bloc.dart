import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecase/get_profile_usecase.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfileUseCase getProfileUseCase;

  ProfileBloc({required this.getProfileUseCase}) : super(ProfileInitial()) {
    on<GetProfileEvent>(_onGetProfile);
  }

  Future<void> _onGetProfile(GetProfileEvent event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final profile = await getProfileUseCase();
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileFailure(e.toString().replaceAll("Exception: ", "")));
    }
  }
}
