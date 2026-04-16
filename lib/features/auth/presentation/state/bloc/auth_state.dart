// abstract class AuthState {}

// class AuthInitial extends AuthState {}

// class AuthLoading extends AuthState {}

// class AuthSuccess extends AuthState {
//   final String token;

//   AuthSuccess(this.token);
// }

// class AuthFailure extends AuthState {
//   final String message;

//   AuthFailure(this.message);
// }


abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;

  AuthSuccess(this.message);
}

class AuthFailure extends AuthState {
  final String error;

  AuthFailure(this.error);
}

class RememberMeLoaded extends AuthState {
  final String username;
  final String password;

  RememberMeLoaded(this.username, this.password);
}

class RememberMeEmpty extends AuthState {}
