import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token, {bool persistent = false});
  Future<String?> getToken();
  Future<void> clearToken();

  Future<void> saveRememberMe(String username, String password);
  Future<(String, String)?> getRememberMe();
  Future<void> clearRememberMe();

  Future<void> saveAutoLogin(bool value);
  Future<bool> isAutoLogin();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  String? _sessionToken;

  AuthLocalDataSourceImpl(this.sharedPreferences);

  static const _tokenKey = 'auth_token';
  static const _rememberUsernameKey = 'remember_username';
  static const _rememberPasswordKey = 'remember_password';
  static const _autoLoginKey = 'is_auto_login';

  @override
  Future<void> saveToken(String token, {bool persistent = false}) async {
    _sessionToken = token;
    if (persistent) {
      await sharedPreferences.setString(_tokenKey, token);
    } else {
      await sharedPreferences.remove(_tokenKey);
    }
  }

  @override
  Future<String?> getToken() async {
    return _sessionToken ?? sharedPreferences.getString(_tokenKey);
  }

  @override
  Future<void> clearToken() async {
    _sessionToken = null;
    await sharedPreferences.remove(_tokenKey);
    await saveAutoLogin(false);
  }

  @override
  Future<void> saveRememberMe(String username, String password) async {
    await sharedPreferences.setString(_rememberUsernameKey, username);
    await sharedPreferences.setString(_rememberPasswordKey, password);
  }

  @override
  Future<(String, String)?> getRememberMe() async {
    final username = sharedPreferences.getString(_rememberUsernameKey);
    final password = sharedPreferences.getString(_rememberPasswordKey);
    if (username != null && password != null) {
      return (username, password);
    }
    return null;
  }

  @override
  Future<void> clearRememberMe() async {
    await sharedPreferences.remove(_rememberUsernameKey);
    await sharedPreferences.remove(_rememberPasswordKey);
  }

  @override
  Future<void> saveAutoLogin(bool value) async {
    await sharedPreferences.setBool(_autoLoginKey, value);
  }

  @override
  Future<bool> isAutoLogin() async {
    return sharedPreferences.getBool(_autoLoginKey) ?? false;
  }
}
