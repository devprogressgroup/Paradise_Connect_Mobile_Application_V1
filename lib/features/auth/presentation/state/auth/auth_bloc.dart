


import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/auth/domain/usecase/clear_remember_me_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/forgot_password_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/get_biometric_enabled_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/get_remember_me_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/login_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/logout_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/reset_password_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/save_biometric_enabled_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/save_credentials_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/update_profile_usecase.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final ResetPasswordUsecase resetPasswordUsecase;
  final GetRememberMeUseCase getRememberMeUseCase;
  final ClearRememberMeUseCase clearRememberMeUseCase;
  final GetBiometricEnabledUseCase getBiometricEnabledUseCase;
  final SaveBiometricEnabledUseCase saveBiometricEnabledUseCase;
  final SaveCredentialsUseCase saveCredentialsUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final LogoutUseCase logoutUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.forgotPasswordUseCase,
    required this.resetPasswordUsecase,
    required this.getRememberMeUseCase,
    required this.clearRememberMeUseCase,
    required this.getBiometricEnabledUseCase,
    required this.saveBiometricEnabledUseCase,
    required this.saveCredentialsUseCase,
    required this.updateProfileUseCase,
    required this.logoutUseCase,
  }) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<ResetPasswordEvent>(_onResetPassword);
    on<CheckRememberMeEvent>(_onCheckRememberMe);
    on<ClearRememberMeEvent>(_onClearRememberMe);
    on<CheckBiometricEnabledEvent>(_onCheckBiometricEnabled);
    on<SaveBiometricEnabledEvent>(_onSaveBiometricEnabled);
    on<SaveCredentialsForBiometricEvent>(_onSaveCredentialsForBiometric);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit,) async {
    emit(AuthLoading());
    try {
      final (user, message) = await loginUseCase(event.username, event.password, rememberMe: event.rememberMe,);
      emit(AuthSuccess(message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onForgotPassword(ForgotPasswordEvent event, Emitter<AuthState> emit, ) async {
    emit(AuthLoading());
    try {
      final (data, message) = await forgotPasswordUseCase(event.phone);
      emit(AuthSuccess(message, data: data));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }


  Future<void> _onResetPassword(  ResetPasswordEvent event,  Emitter<AuthState> emit,) async {
    emit(AuthLoading());

    try {
      final message = await resetPasswordUsecase(event.entity);

      emit(AuthSuccess(message));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onCheckRememberMe(CheckRememberMeEvent event, Emitter<AuthState> emit,) async {
    try {
      final result = await getRememberMeUseCase();

      if (result != null) {
        final (username, password) = result;
        emit(RememberMeLoaded(username, password));
      } else {
        emit(RememberMeEmpty());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onClearRememberMe(ClearRememberMeEvent event, Emitter<AuthState> emit) async {
    try {
      await clearRememberMeUseCase();
      emit(RememberMeEmpty());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onCheckBiometricEnabled(CheckBiometricEnabledEvent event, Emitter<AuthState> emit) async {
    try {
      final enabled = await getBiometricEnabledUseCase();
      emit(BiometricEnabledLoaded(enabled));
    } catch (e) {
      emit(BiometricEnabledLoaded(false));
    }
  }

  Future<void> _onSaveCredentialsForBiometric(SaveCredentialsForBiometricEvent event, Emitter<AuthState> emit) async {
    try {
      await saveCredentialsUseCase(event.username, event.password);
      await saveBiometricEnabledUseCase(true);
      emit(BiometricEnabledLoaded(true));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSaveBiometricEnabled(SaveBiometricEnabledEvent event, Emitter<AuthState> emit) async {
    try {
      await saveBiometricEnabledUseCase(event.enabled);
      emit(BiometricEnabledLoaded(event.enabled));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final message = await updateProfileUseCase(
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
        passwordConfirmation: event.passwordConfirmation,
      );
      emit(AuthSuccess(message));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceAll("Exception: ", "")));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await logoutUseCase();
      emit(AuthLoggedOut());
    } catch (e) {
      // Tetap logout meski ada error
      emit(AuthLoggedOut());
    }
  }
}