import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthLoginRequested>((event, emit) {
      emit(AuthLoading());
      // Handle login login
      emit(AuthAuthenticated());
    });
    on<AuthLogoutRequested>((event, emit) {
      emit(AuthUnauthenticated());
    });
  }
}
