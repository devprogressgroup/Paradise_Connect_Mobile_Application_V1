


import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/features/auth/domain/usecase/forgot_password_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/get_remember_me_usecase.dart';
import 'package:progress_group/features/auth/domain/usecase/login_usecase.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;
  final GetRememberMeUseCase getRememberMeUseCase;

  AuthBloc({ required this.loginUseCase, required this.forgotPasswordUseCase, required this.getRememberMeUseCase, }) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<CheckRememberMeEvent>(_onCheckRememberMe);
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
      emit(AuthSuccess(message));
    } catch (e) {
      emit(AuthFailure(e.toString()));
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
}