import '../../data/models/forgot_password_data_model.dart';
import '../../data/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<(ForgotPasswordDataModel, String)> call(String phone) async {
    return await repository.forgotPassword(phone);
  }
}