


import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/utils/helpers/error_message.dart';
import 'package:progress_group/core/utils/web_debug_util.dart' as web_debug;
import 'package:progress_group/core/utils/helpers/permissions_helper.dart';
import 'package:progress_group/core/utils/helpers/impersonation_manager.dart';
import 'package:progress_group/features/auth/domain/usecase/clear_remember_me_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/forgot_password_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/get_biometric_enabled_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/get_impersonatable_users_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/get_permissions_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/impersonate_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/stop_impersonation_usecase.dart';
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
  final GetPermissionsUseCase getPermissionsUseCase;
  final GetImpersonatableUsersUseCase getImpersonatableUsersUseCase;
  final ImpersonateUseCase impersonateUseCase;
  final StopImpersonationUseCase stopImpersonationUseCase;

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
    required this.getPermissionsUseCase,
    required this.getImpersonatableUsersUseCase,
    required this.impersonateUseCase,
    required this.stopImpersonationUseCase,
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
    on<FetchPermissionsEvent>(_onFetchPermissions);
    on<LoadImpersonatableUsersEvent>(_onLoadImpersonatableUsers);
    on<ImpersonateEvent>(_onImpersonate);
    on<StopImpersonationEvent>(_onStopImpersonation);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit,) async {
    emit(AuthLoading());
    try {
      final (user, message) = await loginUseCase(event.username, event.password, rememberMe: event.rememberMe,);
      emit(LoginSuccess(message));
    } catch (e) {
      emit(AuthFailure(cleanErrorMessage(e)));
    }
  }

  Future<void> _onForgotPassword(ForgotPasswordEvent event, Emitter<AuthState> emit, ) async {
    emit(AuthLoading());
    try {
      final (data, message) = await forgotPasswordUseCase(event.phone);
      emit(AuthSuccess(message, data: data));
    } catch (e) {
      emit(AuthFailure(cleanErrorMessage(e)));
    }
  }


  Future<void> _onResetPassword(  ResetPasswordEvent event,  Emitter<AuthState> emit,) async {
    emit(AuthLoading());

    try {
      final message = await resetPasswordUsecase(event.entity);

      emit(AuthSuccess(message));
    } catch (e) {
      emit(AuthFailure(cleanErrorMessage(e)));
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
      emit(AuthFailure(cleanErrorMessage(e)));
    }
  }

  Future<void> _onClearRememberMe(ClearRememberMeEvent event, Emitter<AuthState> emit) async {
    try {
      await clearRememberMeUseCase();
      emit(RememberMeEmpty());
    } catch (e) {
      emit(AuthFailure(cleanErrorMessage(e)));
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
      emit(AuthFailure(cleanErrorMessage(e)));
    }
  }

  Future<void> _onSaveBiometricEnabled(SaveBiometricEnabledEvent event, Emitter<AuthState> emit) async {
    try {
      await saveBiometricEnabledUseCase(event.enabled);
      emit(BiometricEnabledLoaded(event.enabled));
    } catch (e) {
      emit(AuthFailure(cleanErrorMessage(e)));
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
        photoPath: event.photoPath,
        photoBytes: event.photoBytes,
        photoFilename: event.photoFilename,
      );
      emit(AuthSuccess(message));
    } catch (e) {
      emit(AuthFailure(cleanErrorMessage(e)));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    debugPrint('[AuthBloc] LogoutEvent diterima:\n${StackTrace.current}');
    web_debug.logDebugError('AuthBloc: LogoutEvent diterima — ${StackTrace.current}');
    try {
      await logoutUseCase();
      PermissionsHelper.clear();
      await ImpersonationManager.stop();
      emit(AuthLoggedOut());
    } catch (e) {
      PermissionsHelper.clear();
      await ImpersonationManager.stop();
      emit(AuthLoggedOut());
    }
  }

  Future<void> _onFetchPermissions(FetchPermissionsEvent event, Emitter<AuthState> emit) async {
    if (!event.silent) emit(PermissionsLoading());
    try {
      final data = await getPermissionsUseCase();
      PermissionsHelper.init(data);
      emit(PermissionsLoaded(data));
    } catch (e) {
     
     
     
      if (!event.silent) emit(PermissionsError());
    }
  }

 
  Future<void> _onLoadImpersonatableUsers(LoadImpersonatableUsersEvent event, Emitter<AuthState> emit) async {
    emit(ImpersonatableUsersLoading());
    try {
      final users = await getImpersonatableUsersUseCase(search: event.search);
      emit(ImpersonatableUsersLoaded(users));
    } catch (e) {
      emit(ImpersonatableUsersError(cleanErrorMessage(e)));
    }
  }

  Future<void> _onImpersonate(ImpersonateEvent event, Emitter<AuthState> emit) async {
    emit(ImpersonationInProgress());
    try {
      final targetName = await impersonateUseCase(event.userId);
      await ImpersonationManager.start(targetName);
      emit(ImpersonationStarted(targetName));
    } catch (e) {
      emit(ImpersonationFailure(cleanErrorMessage(e)));
    }
  }

  Future<void> _onStopImpersonation(StopImpersonationEvent event, Emitter<AuthState> emit) async {
    emit(ImpersonationInProgress());
    try {
      await stopImpersonationUseCase();
      await ImpersonationManager.stop();
      emit(ImpersonationStopped());
    } catch (e) {
      emit(ImpersonationFailure(cleanErrorMessage(e)));
    }
  }
}
