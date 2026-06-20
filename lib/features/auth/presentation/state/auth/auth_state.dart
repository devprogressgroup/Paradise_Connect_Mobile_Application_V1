abstract class AuthState {}

class AuthInitial extends AuthState {}



class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  final dynamic data;

  AuthSuccess(this.message, {this.data});
}

// State khusus untuk login berhasil — hanya ini yang trigger authNotifier
class LoginSuccess extends AuthState {
  final String message;
  LoginSuccess(this.message);
}

class AuthFailure extends AuthState {
  final String error;

  AuthFailure(this.error);
}




class BiometricEnabledLoaded extends AuthState {
  final bool enabled;
  BiometricEnabledLoaded(this.enabled);
}

class RememberMeLoaded extends AuthState {
  final String username;
  final String password;

  RememberMeLoaded(this.username, this.password);
}

class RememberMeEmpty extends AuthState {}

class AuthLoggedOut extends AuthState {}

class PermissionsLoading extends AuthState {}

class PermissionsLoaded extends AuthState {
  final dynamic data;
  PermissionsLoaded(this.data);
}

class PermissionsError extends AuthState {}

// ── Impersonation (superadmin login-as) ──────────────────────────────
class ImpersonatableUsersLoading extends AuthState {}

class ImpersonatableUsersLoaded extends AuthState {
  final List<dynamic> users; // List<ImpersonatableUser>
  ImpersonatableUsersLoaded(this.users);
}

class ImpersonatableUsersError extends AuthState {
  final String message;
  ImpersonatableUsersError(this.message);
}

class ImpersonationInProgress extends AuthState {}

class ImpersonationStarted extends AuthState {
  final String targetName;
  ImpersonationStarted(this.targetName);
}

class ImpersonationStopped extends AuthState {}

class ImpersonationFailure extends AuthState {
  final String message;
  ImpersonationFailure(this.message);
}
