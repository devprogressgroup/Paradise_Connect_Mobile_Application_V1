import '../../data/repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<String> call({String? email, String? phoneNumber, String? password, String? passwordConfirmation}) async {
    return await repository.updateProfile(
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }
}
