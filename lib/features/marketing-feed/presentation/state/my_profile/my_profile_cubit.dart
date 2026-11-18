import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/marketing-feed/domain/entities/my_profile_entity.dart';
import 'package:progress_group/features/marketing-feed/domain/usecases/get_my_profile_usecase.dart';

enum MyProfileStatus { initial, loading, loaded, error }

class MyProfileState {
  final MyProfileStatus status;
  final MyProfileEntity? profile;
  final String? errorMessage;

  const MyProfileState({
    this.status = MyProfileStatus.initial,
    this.profile,
    this.errorMessage,
  });
}

/// State halaman profil Marketing Feed (punya sendiri atau user lain).
class MyProfileCubit extends Cubit<MyProfileState> {
  final GetMyProfileUseCase getMyProfileUseCase;

  MyProfileCubit({required this.getMyProfileUseCase})
    : super(const MyProfileState());

  Future<void> fetch({int? userId}) async {
    emit(
      MyProfileState(status: MyProfileStatus.loading, profile: state.profile),
    );
    final result = await getMyProfileUseCase(userId: userId);
    if (isClosed) return;
    result.fold(
      (message) => emit(
        MyProfileState(status: MyProfileStatus.error, errorMessage: message),
      ),
      (data) =>
          emit(MyProfileState(status: MyProfileStatus.loaded, profile: data)),
    );
  }
}
