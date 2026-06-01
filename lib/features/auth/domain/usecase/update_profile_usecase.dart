import '../../data/repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<String> call({String? email, String? phoneNumber, String? password, String? passwordConfirmation, String? photoPath, List<int>? photoBytes, String? photoFilename}) async {
    return await repository.updateProfile(
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      passwordConfirmation: passwordConfirmation,
      photoPath: photoPath,
      photoBytes: photoBytes,
      photoFilename: photoFilename,
    );
  }
}
